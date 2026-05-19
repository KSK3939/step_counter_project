#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

/* ── Base addresses ── */
#define MPU_ADDR    XPAR_I2C_MPU_IP_0_BASEADDR
#define STEP_ADDR   XPAR_STEP_COUNTER_IP_0_BASEADDR
#define RXTX_ADDR   XPAR_MYIP_RXTX_0_BASEADDR
#define DOT_ADDR    XPAR_DOTMATRIX_IP_0_BASEADDR

/* ── MPU IP register offsets ── */
#define REG_VALID_OFFSET      4
#define REG_AX_OFFSET         8
#define REG_AY_OFFSET         12
#define REG_AZ_OFFSET         16

/* ── STEP_COUNTER IP register offsets ── */
#define STEP_COUNT_OFFSET            0
#define STEP_DISTANCE_OFFSET         4
#define STEP_MOTION_OFFSET           8   /* 변경: STEP_AZ_OFFSET → STEP_MOTION_OFFSET */
#define STEP_HIGH_TH_OFFSET          12
#define STEP_LOW_TH_OFFSET           16
#define STEP_MIN_STEP_SAMPLE_OFFSET  20
#define STEP_BASE_SHIFT_OFFSET       24
#define STEP_CALIB_SAMPLE_OFFSET     28

/* ── MYIP_RXTX register offsets ── */
#define RXTX_TX_DATA_OFFSET   0x00
#define RXTX_STATUS_OFFSET    0x04
#define RXTX_BAUD_OFFSET      0x08
#define RXTX_RX_DATA_OFFSET   0x0C

/* ── Status register bit masks ── */
#define STATUS_TX_BUSY        (1 << 0)
#define STATUS_TX_READY       (1 << 1)
#define STATUS_TX_DONE_FLAG   (1 << 2)
#define STATUS_RX_BUSY        (1 << 3)
#define STATUS_RX_DONE_FLAG   (1 << 4)
#define STATUS_RX_ERROR_FLAG  (1 << 5)

/* ── Flag clear bits ── */
#define CLEAR_TX_DONE_FLAG    (1 << 2)
#define CLEAR_RX_DONE_FLAG    (1 << 4)
#define CLEAR_RX_ERROR_FLAG   (1 << 5)

#define CLK_HZ        100000000UL
#define BAUD_RATE     9600UL
#define BAUD_DIV_VAL  ((CLK_HZ / BAUD_RATE) - 1)

/* ── 상태 머신 ── */
typedef enum {
    STATE_WAIT_GOAL,
    STATE_RUNNING,
    STATE_DONE
} AppState;

/* ── 루프 주기 (usleep 단위) ── */
#define LOOP_INTERVAL_US   200000UL   /* 200 ms */
#define LOOPS_PER_SEC      5UL        /* 1000ms / 200ms */

/* ── Dot Matrix ── */
volatile unsigned int *dot_cntr = (volatile unsigned int*)DOT_ADDR;

void dot_matrix_control(int num)
{
    if (num > 9999) num = 9999;
    if (num < 0)    num = 0;

    dot_cntr[3] = (unsigned int)num;

    dot_cntr[1] = 0;
    dot_cntr[1] = 1;
    dot_cntr[1] = 0;
}

/* ── TX 함수 ── */
static void rxtx_send_byte(uint8_t c)
{
    uint32_t status;
    do {
        status = Xil_In32(RXTX_ADDR + RXTX_STATUS_OFFSET);
    } while (status & STATUS_TX_BUSY);

    Xil_Out32(RXTX_ADDR + RXTX_TX_DATA_OFFSET, (uint32_t)c);
    Xil_Out32(RXTX_ADDR + RXTX_STATUS_OFFSET, CLEAR_TX_DONE_FLAG);
}

static void rxtx_send_str(const char *s)
{
    while (*s) rxtx_send_byte((uint8_t)*s++);
}

static void rxtx_send_uint(uint32_t val)
{
    char buf[12];
    int  i = 0;
    if (val == 0) { rxtx_send_byte('0'); return; }
    while (val > 0) { buf[i++] = '0' + (val % 10); val /= 10; }
    while (i > 0)   { rxtx_send_byte((uint8_t)buf[--i]); }
}

/* ── RX 함수 (논블로킹) ── */
static int rxtx_recv_byte(uint8_t *out)
{
    uint32_t status = Xil_In32(RXTX_ADDR + RXTX_STATUS_OFFSET);

    if (status & STATUS_RX_ERROR_FLAG) {
        Xil_Out32(RXTX_ADDR + RXTX_STATUS_OFFSET, CLEAR_RX_ERROR_FLAG);
        return 0;
    }
    if (status & STATUS_RX_DONE_FLAG) {
        *out = (uint8_t)(Xil_In32(RXTX_ADDR + RXTX_RX_DATA_OFFSET) & 0xFF);
        Xil_Out32(RXTX_ADDR + RXTX_STATUS_OFFSET, CLEAR_RX_DONE_FLAG);
        return 1;
    }
    return 0;
}

static int rxtx_recv_goal(uint32_t *goal_out)
{
    char buf[6] = {0};
    int  idx = 0;
    uint8_t ch;

    int started    = 0;
    int idle_count = 0;

    while (1) {
        if (rxtx_recv_byte(&ch)) {
            if (ch >= '0' && ch <= '9') {
                if (idx < 4) {
                    buf[idx++] = (char)ch;
                    started    = 1;
                    idle_count = 0;
                }
                if (idx >= 4) break;
            } else if (ch == '\r' || ch == '\n') {
                if (started) break;
            }
        } else {
            if (started) {
                idle_count++;
                if (idle_count >= 500000) break;
            } else {
                usleep(100);
            }
        }
    }

    buf[idx] = '\0';
    if (idx == 0) return 0;

    *goal_out = (uint32_t)atoi(buf);
    printf("DEBUG : buf = '%s' goal = %u\r\n", buf, (unsigned int)*goal_out);
    return 1;
}

/* ── 시간 포맷 출력 (초 → MM:SS) ── */
static void rxtx_send_time(uint32_t total_sec)
{
    uint32_t m = total_sec / 60;
    uint32_t s = total_sec % 60;
    rxtx_send_byte('0' + (uint8_t)(m / 10));
    rxtx_send_byte('0' + (uint8_t)(m % 10));
    rxtx_send_byte(':');
    rxtx_send_byte('0' + (uint8_t)(s / 10));
    rxtx_send_byte('0' + (uint8_t)(s % 10));
}

static void rxtx_send_speed(uint32_t dist_cm, uint32_t elapsed_sec)
{
    if (elapsed_sec == 0) {
        rxtx_send_str("-.-- km/h");
        return;
    }
    uint32_t denom   = elapsed_sec * 1000UL;
    uint32_t numer   = dist_cm * 36UL;
    uint32_t integer = numer / denom;
    uint32_t frac    = ((numer % denom) * 10UL) / denom;

    rxtx_send_uint(integer);
    rxtx_send_byte('.');
    rxtx_send_byte('0' + (uint8_t)frac);
    rxtx_send_str(" km/h");
}

int main()
{
    init_platform();

    /* Baud rate 설정 */
    Xil_Out32(RXTX_ADDR + RXTX_BAUD_OFFSET, BAUD_DIV_VAL);

    /* Dot Matrix 초기화 */
    dot_cntr[0] = 1;
    sleep(1);
    dot_matrix_control(0);

    print("\n\r==========================================\n\r");
    print("   MPU9250 + Step Counter + Dot Matrix    \n\r");
    print("==========================================\n\r");

    int32_t  raw_ax, raw_ay, raw_az;
    uint32_t valid_status;
    uint32_t step_count;
    uint32_t distance_cm;
    int32_t  step_motion;   /* 변경: step_az → step_motion */

    uint32_t base_step_count = 0;
    uint32_t base_distance   = 0;
    uint32_t prev_step_count = 0;
    uint32_t elapsed_loops   = 0;

    /* ── 변경: 참조 코드 기준 임계값으로 업데이트 ── */
    Xil_Out32(STEP_ADDR + STEP_HIGH_TH_OFFSET,         10000);
    Xil_Out32(STEP_ADDR + STEP_LOW_TH_OFFSET,           5000);
    Xil_Out32(STEP_ADDR + STEP_MIN_STEP_SAMPLE_OFFSET,   100);
    Xil_Out32(STEP_ADDR + STEP_BASE_SHIFT_OFFSET,           5);
    Xil_Out32(STEP_ADDR + STEP_CALIB_SAMPLE_OFFSET,      100);

    uint32_t goal  = 0;
    AppState state = STATE_WAIT_GOAL;

    rxtx_send_str("Enter goal steps (1~9999):\r\n");
    printf("Enter goal steps (1~9999):\r\n");

    while (1) {

        /* ══ STATE_WAIT_GOAL ══ */
        if (state == STATE_WAIT_GOAL) {
            if (rxtx_recv_goal(&goal)) {
                rxtx_send_str("Input : ");
                rxtx_send_uint(goal);
                rxtx_send_str("\r\n");

                if (goal >= 1 && goal <= 9999) {
                    base_step_count = Xil_In32(STEP_ADDR + STEP_COUNT_OFFSET);
                    base_distance   = Xil_In32(STEP_ADDR + STEP_DISTANCE_OFFSET);
                    prev_step_count = base_step_count;

                    rxtx_send_str("START! Goal: ");
                    rxtx_send_uint(goal);
                    rxtx_send_str(" steps\r\n");
                    printf("START! Goal: %u steps\r\n", (unsigned int)goal);

                    dot_matrix_control(0);
                    elapsed_loops = 0;

                    state = STATE_RUNNING;
                } else {
                    rxtx_send_str("Enter 1~9999:\r\n");
                    printf("Enter 1~9999:\r\n");
                }
            }
            continue;
        }

        /* ══ STATE_RUNNING ══ */
        if (state == STATE_RUNNING) {

            /* MPU 값 읽기 */
            valid_status = Xil_In32(MPU_ADDR + REG_VALID_OFFSET);
            raw_ax       = (int32_t)Xil_In32(MPU_ADDR + REG_AX_OFFSET);
            raw_ay       = (int32_t)Xil_In32(MPU_ADDR + REG_AY_OFFSET);
            raw_az       = (int32_t)Xil_In32(MPU_ADDR + REG_AZ_OFFSET);

            /* Step Counter 값 읽기 */
            step_count  = Xil_In32(STEP_ADDR + STEP_COUNT_OFFSET);
            distance_cm = Xil_In32(STEP_ADDR + STEP_DISTANCE_OFFSET);
            step_motion = (int32_t)Xil_In32(STEP_ADDR + STEP_MOTION_OFFSET); /* 변경 */

            /* 오프셋 적용 */
            uint32_t rel_step = (step_count >= base_step_count)
                                ? (step_count - base_step_count) : 0;
            uint32_t rel_dist = (distance_cm >= base_distance)
                                ? (distance_cm - base_distance) : 0;

            dot_matrix_control((int)rel_step);

            elapsed_loops++;
            uint32_t elapsed_sec = elapsed_loops / LOOPS_PER_SEC;

            prev_step_count = step_count;

            /* 변경: step_az → step_motion, STEP_AZ → MOTION */
            printf("MPU X:%d Y:%d Z:%d V:%u | STEP:%u/%u DIST:%u cm MOTION:%d | TIME:%us\r\n",
                   (int)raw_ax, (int)raw_ay, (int)raw_az,
                   (unsigned int)valid_status,
                   (unsigned int)rel_step,
                   (unsigned int)goal,
                   (unsigned int)rel_dist,
                   (int)step_motion,
                   (unsigned int)elapsed_sec);

            /* 목표 달성 확인 */
            if (rel_step >= goal) {
                uint32_t final_sec = elapsed_loops / LOOPS_PER_SEC;

                rxtx_send_str("\r\n*** PERFECT! Goal reached! ***\r\n");
                rxtx_send_str("Final STEP : "); rxtx_send_uint(rel_step);  rxtx_send_str(" steps\r\n");
                rxtx_send_str("Final DIST : "); rxtx_send_uint(rel_dist);  rxtx_send_str(" cm\r\n");
                rxtx_send_str("Time       : "); rxtx_send_time(final_sec); rxtx_send_str(" (MM:SS)\r\n");
                rxtx_send_str("Speed      : "); rxtx_send_speed(rel_dist, final_sec); rxtx_send_str("\r\n");

                printf("\r\n*** PERFECT! Goal reached! ***\r\n");
                printf("Final STEP: %u steps / DIST: %u cm / TIME: %us\r\n",
                       (unsigned int)rel_step, (unsigned int)rel_dist, (unsigned int)final_sec);

                state = STATE_DONE;
                continue;
            }

            /* 's' 입력 확인 (중도 포기) */
            uint8_t ch;
            if (rxtx_recv_byte(&ch)) {
                if (ch == 's' || ch == 'S') {
                    uint32_t final_sec = elapsed_loops / LOOPS_PER_SEC;

                    rxtx_send_str("\r\n*** FAIL! Stopped. ***\r\n");
                    rxtx_send_str("Final STEP : "); rxtx_send_uint(rel_step);  rxtx_send_str(" steps\r\n");
                    rxtx_send_str("Final DIST : "); rxtx_send_uint(rel_dist);  rxtx_send_str(" cm\r\n");
                    rxtx_send_str("Time       : "); rxtx_send_time(final_sec); rxtx_send_str(" (MM:SS)\r\n");
                    rxtx_send_str("Speed      : "); rxtx_send_speed(rel_dist, final_sec); rxtx_send_str("\r\n");

                    printf("\r\n*** FAIL! Stopped. ***\r\n");
                    printf("Final STEP: %u steps / DIST: %u cm / TIME: %us\r\n",
                           (unsigned int)rel_step, (unsigned int)rel_dist, (unsigned int)final_sec);

                    state = STATE_DONE;
                    continue;
                }
            }

            usleep(LOOP_INTERVAL_US);
        }

        /* ══ STATE_DONE ══ */
        if (state == STATE_DONE) {
            usleep(10000000UL);

            goal          = 0;
            elapsed_loops = 0;
            dot_matrix_control(0);

            rxtx_send_str("\r\n----------------------------------\r\n");
            rxtx_send_str("Enter goal steps (1~9999):\r\n");
            printf("Enter goal steps (1~9999):\r\n");

            state = STATE_WAIT_GOAL;
        }
    }

    cleanup_platform();
    return 0;
}