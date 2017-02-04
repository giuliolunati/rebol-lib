PACKAGE = rebol-lib
VERSION = 0.0.1
PLATFORM = all
ARCH = all
DESCRIPTION = "some Rebol libraries"
DEB = ${PACKAGE}_${VERSION}_${PLATFORM}.deb
FILES = \
usr/bin/rebol.r \
usr/lib/r3/altjson.reb \
usr/lib/r3/complex.reb \
usr/lib/r3/csv.reb \
usr/lib/r3/custom.reb \
usr/lib/r3/dot.reb \
usr/lib/r3/fraction.reb \
usr/lib/r3/html.reb \
usr/lib/r3/profile.reb \
usr/lib/r3/rec.reb \
usr/lib/r3/rem.reb \
usr/lib/r3/rewrite.r \
usr/lib/r3/shttpd.reb \
usr/lib/r3/sl4a.reb \
usr/lib/r3/sort.reb \
usr/lib/r3/text.reb \
usr/lib/r3/websy.reb \
usr/share/doc/r3/rem-tutorial.html \
usr/share/scripts/demo-complex.reb \
usr/share/scripts/demo-csv.reb \
usr/share/scripts/demo-fraction.reb \
usr/share/scripts/demo-html.reb \
usr/share/scripts/demo-rec.reb \
usr/share/scripts/demo-rem.reb \
usr/share/scripts/factors.reb \
usr/share/scripts/shttpd.reb

${DEB}: data.tar.gz control.tar.gz debian-binary makefile
	ar r $@ debian-binary control.tar.gz data.tar.gz

data.tar.gz: ${FILES} clean-usr
	tar cf data.tar usr
	rm -f data.tar.gz
	gzip data.tar

control.tar.gz: control
	tar cf control.tar ./control
	rm -f control.tar.gz
	gzip control.tar

debian-binary:
	echo 2.0 > $@

control:
	echo "Package: ${PACKAGE}" > $@
	echo "Version: ${VERSION}" >> $@
	echo "Architecture: ${ARCH}" >> $@
	echo "Description:" >> $@
	echo "" >> $@

.PHONY: sync
sync:
	@for o in ${FILES}; do \
	  i=$$ROOT/$$o; \
		if [ -d $$i -o -d $$o ]; then continue; fi; \
	  if [ ! -e $$o -o $$i -nt $$o ]; then \
	    echo update '->' $$o '?'; \
	    echo '[(yes) r(everse), n(o)]'; \
	    read x; \
	    case $$x in \
	    r*) cp -a $$o $$i ;; \
	    n*) ;; \
	    *) cp -a $$i $$o ;; \
	    esac; \
	  else \
	    if [ ! -e $$i -o $$o -nt $$i ]; then \
	      echo install '<-' $$o '?'; \
	      echo '[(yes), r(everse), n(o)]';\
	      read x; \
	      case $$x in \
	      r*) cp -a $$i $$o ;; \
	      n*) ;; \
	      *) cp -a $$o $$i ;; \
	      esac; \
	    fi; \
	  fi; \
	done

.PHONY: comp
comp:
	@for o in ${FILES}; do \
	  i=$$ROOT/$$o; \
	  [ -f $$i ] || continue; \
	  if [ $$i -nt $$o ]; then \
	    echo update '->' $$o; \
	  else \
	    if [ $$o -nt $$i ]; then \
	      echo install '<-' $$o; \
	    fi; \
	  fi; \
	done

.PHONY: clean
clean:
	rm -f ${DEB} control.tar.gz data.tar.gz
	rm -f control debian-binary

.PHONY: clean-usr
clean-usr: makefile
	@ rm _
	@ for i in ${FILES}; do echo $$i >> _; done
	@ find usr -type f >> _
	@ for i in `sort _  | uniq -u`; do\
		case $$i in\
		*~) rm -f $$i ;;\
		*)  rm -i $$i ;;\
		esac; done
	@ rm _


# vim: set ts=2 sts=2 sw=2 :
