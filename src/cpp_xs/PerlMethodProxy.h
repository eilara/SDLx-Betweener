
#ifndef PERLMETHODPROXY_H
#define PERLMETHODPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "IProxy.h"

template<typename T,int DIM>
class PerlMethodProxy : public IProxy<T,DIM>  {

    public:
        // on_sv is array ref of method, target
        PerlMethodProxy(SV *on_sv) {
           AV* on_av      = (AV*) SvRV(on_sv);
           SV** method_sv = av_fetch(on_av, 0, 0);
           SV** target_sv = av_fetch(on_av, 1, 0);
           method         = strdup((char*) SvPV_nolen(*method_sv));
           // weak ref on target object
           target         = newRV_inc(SvRV(*target_sv));
           sv_rvweaken(target);
        }
        ~PerlMethodProxy() {
            delete method;
            SvREFCNT_dec(target);
        }
        void update(Vector1i& value) {
            SV* out = newSViv(value[0]);
            update_method(out);
        }
        void update(Vector1f& value) {
            SV* out = newSVnv(value[0]);
            update_method(out);
        }
        void update(Vector2i& value) {
            AV* arr = newAV();
            av_extend(arr, 1);
            av_store(arr, 0, newSViv(value[0]));
            av_store(arr, 1, newSViv(value[1]));
            update_method((SV*) newRV_noinc((SV*) arr));
        }
        void update(Vector4c& value) {
            Uint32 color = (value[0] << 24) |
                           (value[1] << 16) |
                           (value[2] <<  8) |
                            value[3];
            SV* out = newSViv(color);
            update_method(out);
        }

        void update_method(SV *out) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 2);
            XPUSHs(target);
            XPUSHs(sv_2mortal(out));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;
        }
    private:
        SV   *target;
        char *method;

};

#endif
