
#ifndef IPERLDIRECTPROXY_H
#define IPERLDIRECTPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <iostream>
#include "Vector.h"
#include "IProxy.h"


template<typename T,int DIM>
class PerlDirectProxy : public IProxy<T,DIM>  {

    public:
        // val is rv on sv or av
        PerlDirectProxy(SV* val) {
            // weak ref on target
            target = SvRV(val);
        }
        ~PerlDirectProxy() {
        }
        void update(Vector<int,1>& value) {
            SvIV_set((SV*) target, value[0]);
        }
        void update(Vector<float,1>& value) {
            SvNV_set(target, value[0]);
        }
        void update(Vector<int,2>& value) {
            AV* arr = (AV*) target;
            SV** v1 = av_fetch(arr, 0, 0);
            SV** v2 = av_fetch(arr, 1, 0);
            SvIV_set(*v1, value[0]);
            SvIV_set(*v2, value[1]);
        }

     private:
        SV *target;

};

#endif
