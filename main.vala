using Posix;

void mylog(void* data,
			   string file,
			   int line,
			   string func,
			   string subs,
			   uint sev,
			   string format,
			   va_list args){
}

int main (string[] args) {
  Tsm.Screen screen;
  if (Tsm.Screen.Screen_new(out  screen, mylog, null) <0){
    printf("Unable to create screen");
  }
return 0;
}
