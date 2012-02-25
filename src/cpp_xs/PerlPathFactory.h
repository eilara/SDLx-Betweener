
#ifndef PERLPATHFACTORY_H
#define PERLPATHFACTORY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "VectorTypes.h"
#include "IPath.h"
#include "LinearPath.h"

Vector2i av_to_vec_2D(SV *rv) {
    AV*      arr = (AV*) SvRV(rv);
    SV**     e1  = av_fetch(arr, 0, 0);
    SV**     e2  = av_fetch(arr, 1, 0);
    Vector2i v   = { {(int) SvIV(*e1), (int) SvIV(*e2)} };
    return v;
}

IPath *Build_Path(int path_type, SV *path_args) {
    HV* args      = (HV*) SvRV(path_args);
    SV** from_sv  = hv_fetch(args, "from", 4, 0);
    SV** to_sv    = hv_fetch(args, "to"  , 2, 0);
    Vector2i from = av_to_vec_2D(*from_sv);
    Vector2i to   = av_to_vec_2D(*to_sv);
    IPath *path = new LinearPath(from, to);
    return path;
}



#endif
