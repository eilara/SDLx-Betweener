
#include "Types.h"
#include "Tween.h"
#include "SDL.h"

MODULE = SDLx::Betweener  PACKAGE = SDLx::Betweener::Tween

#define COMPUTE_NOW()            \
    Uint32 now = items == 2?     \
        (Uint32) SvIV(ST(1)):    \
        (Uint32) SDL_GetTicks(); \

void
Tween::start(...)
    CODE:
        COMPUTE_NOW()
        THIS->start(now);

void
Tween::stop()

void
Tween::pause(...)
    CODE:
        COMPUTE_NOW()
        THIS->pause(now);

void
Tween::resume(...)
    CODE:
        COMPUTE_NOW()
        THIS->resume(now);

void
Tween::DESTROY()
    CODE:
        delete THIS;


