
#ifndef IPERLCALLBACKPROXY_H
#define IPERLCALLBACKPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "IProxy.h"

template<typename T,int DIM>
class PerlCallbackProxy : public IProxy<T,DIM>  {

    public:
        // cb is rv on callback
        PerlCallbackProxy(SV *cb) {
            // strong ref clone of callback
            callback = newSVsv(cb);
        }
        ~PerlCallbackProxy() {
            SvREFCNT_dec(callback);
        }
        void update(Vector1i& value) {
            SV* out = newSViv(value[0]);
            update_callback(out);
        }
        void update(Vector1f& value) {
            SV* out = newSVnv(value[0]);
            update_callback(out);
        }
        void update(Vector2i& value) {
            AV* arr = newAV();
            av_extend(arr, 1);
            av_store(arr, 0, newSViv(value[0]));
            av_store(arr, 1, newSViv(value[1]));
            update_callback((SV*) newRV_noinc((SV*) arr));
        }
        void update(Vector4c& value) {
            Uint32 color = (value[0] << 24) |
                           (value[1] << 16) |
                           (value[2] <<  8) |
                            value[3];
            SV* out = newSViv(color);
            update_callback(out);
        }
        void update_callback(SV *out) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 1);
            XPUSHs(sv_2mortal(out));
            PUTBACK;
            call_sv(callback, G_DISCARD);
            FREETMPS; LEAVE;
        }
    private:
        SV *callback;

};

#endif
