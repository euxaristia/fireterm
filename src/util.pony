use "time"
use "collections"
use @write[ISize](fd: I32, buffer: Pointer[None], bytes_to_send: I32)
use @usleep[I32](usecs: U32)

primitive XorShift64
  """Xorshift64* PRNG"""
  fun apply(seed: U64): (U64, F64) =>
    var s = seed
    s = s xor (s >> 12)
    s = s xor (s << 25)
    s = s xor (s >> 27)
    let result = s * 0x2545F4914F6CDD1D
    (s, (result.f64() / 18446744073709551616.0).max(0.0).min(1.0))


class Rand
  """Simple RNG wrapper using Xorshift64*"""
  var _state: U64

  new create(seed: U64) =>
    _state = seed

  fun ref apply(): F64 =>
    let result = XorShift64(_state)
    _state = result._1
    result._2


primitive Clock
  fun now(): U64 =>
    Time.nanos()


primitive U8Clamp
  fun apply(v: F64): U8 =>
    if v < 0 then 0
    elseif v > 255 then 255
    else v.u8()
    end