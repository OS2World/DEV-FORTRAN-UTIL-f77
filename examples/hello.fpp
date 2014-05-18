      PROGRAM example1
#ifdef FUNKY
#ifdef VAX
      WRITE (*,*) 'HEY WHATS HAPPENIN THERE WORLD'
#else
      WRITE (*,*) 'Hey what\'s happenin\' there world'
#endif
#else
#ifdef VAX
      WRITE (*,*) 'HELLO WORLD'
#else
      WRITE (*,*) 'Hello World'
#endif
#endif
      STOP
      END
