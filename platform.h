
__attribute__((noreturn)) void platform_panic();
__attribute__((noreturn)) void platform_exit();
int platform_open_file(char *fname);
int platform_reset_file(int fd);
int platform_read_char(int fd);
void platform_write_char(int fd, int c);
void platform_log(int fd, char *s);
