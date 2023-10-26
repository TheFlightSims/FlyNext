// Declaration for simgear callback
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <functional>

#ifndef _SG_CALLBACK_HXX
#define _SG_CALLBACK_HXX

namespace simgear {
    using Callback = std::function<void()>;
}

#endif // _SG_CALLBACK_HXX
