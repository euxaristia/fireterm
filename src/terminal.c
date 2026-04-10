#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>

static struct termios orig_termios;
static int raw_mode_enabled = 0;

void term_enable_raw(void) {
    if (raw_mode_enabled) return;
    tcgetattr(STDIN_FILENO, &orig_termios);
    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
    raw_mode_enabled = 1;
}

void term_disable_raw(void) {
    if (!raw_mode_enabled) return;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
    raw_mode_enabled = 0;
}

int term_key_pressed(void) {
    char c;
    return read(STDIN_FILENO, &c, 1) == 1;
}

void term_get_size(int *rows, int *cols) {
    struct winsize w;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0) {
        *rows = w.ws_row;
        *cols = w.ws_col;
    } else {
        *rows = 24;
        *cols = 80;
    }
}

void term_hide_cursor(void) {
    write(STDOUT_FILENO, "\033[?25l", 6);
}

void term_show_cursor(void) {
    write(STDOUT_FILENO, "\033[?25h", 6);
}
