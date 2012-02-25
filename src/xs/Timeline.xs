
#include "CycleControl.h"
#include "Timeline.h"
#include "PerlMethodCompleter.h"
#include "PerlProxyFactory.h"
#include "PerlPathFactory.h"

MODULE = SDLx::Betweener         PACKAGE = SDLx::Betweener::Timeline

Timeline *
Timeline::new()

void
Timeline::tick(now)
    Uint32 now

Tween *
Timeline::_tween_int(proxy_type, proxy_args, duration, from, to, ease, forever, repeat, bounce, reverse)
    int    proxy_type
    SV    *proxy_args
    int    duration
    int    from
    int    to
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    CODE:
        IProxy<int,1>       *proxy     = Build_Proxy<int,1>(proxy_type, proxy_args);
        PerlMethodCompleter *completer = new PerlMethodCompleter();
        CycleControl        *control   = new CycleControl(forever, repeat, bounce, reverse);
        Tween               *tween     = THIS->build_int_tween(proxy, completer, duration, from, to, ease, control);
        char                 CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                         = tween;
    OUTPUT:
        RETVAL

Tween *
Timeline::_tween_float(proxy_type, proxy_args, duration, from, to, ease, forever, repeat, bounce, reverse)
    int    proxy_type
    SV    *proxy_args
    int    duration
    float  from
    float  to
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    CODE:
        IProxy<float,1>     *proxy     = Build_Proxy<float,1>(proxy_type, proxy_args);
        PerlMethodCompleter *completer = new PerlMethodCompleter();
        CycleControl        *control   = new CycleControl(forever, repeat, bounce, reverse);
        Tween               *tween     = THIS->build_float_tween(proxy, completer, duration, from, to, ease, control);
        char                 CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                         = tween;
    OUTPUT:
        RETVAL

Tween *
Timeline::_tween_path(proxy_type, proxy_args, duration, path_type, path_args, ease, forever, repeat, bounce, reverse)
    int    proxy_type
    SV    *proxy_args
    int    duration
    int    path_type
    SV    *path_args
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    CODE:
        IProxy<int,2>       *proxy     = Build_Proxy<int,2>(proxy_type, proxy_args);
        PerlMethodCompleter *completer = new PerlMethodCompleter();
        CycleControl        *control   = new CycleControl(forever, repeat, bounce, reverse);
        IPath               *path      = Build_Path(path_type, path_args);
        Tween               *tween     = THIS->build_path_tween(proxy, completer, duration, path, ease, control);
        char                 CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                         = tween;
    OUTPUT:
        RETVAL


