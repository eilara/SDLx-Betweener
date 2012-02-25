
#ifndef IPERLMETHODCOMPLETER_H
#define IPERLMETHODCOMPLETER_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <iostream>
#include "Types.h"
#include "ICompleter.h"

class PerlMethodCompleter : public ICompleter  {

    public:
        PerlMethodCompleter() {}
        ~PerlMethodCompleter() {}
        void animation_complete(Uint32 now) {
            std::cout << "#\n# animation_complete called: " << now << "\n#" << std::endl;
        }

};

#endif
