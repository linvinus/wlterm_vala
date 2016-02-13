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

void my_write_cb(Tsm.Vte vte,
      string u8,
      size_t len,
      void* data){
}


int main (string[] args) {
  Tsm.Screen screen;
  Tsm.Vte vte;
  if (Tsm.Screen.Screen_new(out  screen, mylog, null) <0){
    printf("Unable to create screen");
  }
  screen.set_max_sb(500);
  if( Tsm.Vte.Vte_new(out vte,screen,my_write_cb,null,mylog, null) <0){
    printf("Unable to create vte");
  }
return 0;
}
