# sv-fifo-project1
Feature Roadmap

V1
✓ Basic synchronous FIFO
✓ count-based full/empty

V2
✓ Almost Full
✓ Almost Empty

V3
✓ FWFT (First Word Fall Through)

V4
✓ Asynchronous FIFO
✓ Gray Code Pointer
✓ CDC Synchronizer

V5
✓ Full UVM Verification
✓ Assertion
✓ Functional Coverage

//==============================================================================
// FIFO Specification
//==============================================================================
//
// FIFO Type
//   - Synchronous FIFO
//   - Single clock domain
//   - Active-low asynchronous reset (rst_n)
//
// Parameters
//   - WIDTH : Data width
//   - DEPTH : Number of FIFO entries
//
// Internal States
//   - memory
//   - write_ptr
//   - read_ptr
//   - count
//
// Reset Behavior
//   - write_ptr = 0
//   - read_ptr  = 0
//   - count     = 0
//   - dout      = 0
//   - memory is NOT cleared during reset
//
// Status Flags
//   - empty = (count == 0)
//   - full  = (count == DEPTH)
//
// Write Operation
//   Condition:
//     wr_en && !full
//
//   Behavior:
//     memory[write_ptr] <= din
//     write_ptr++
//     count++
//
// Read Operation
//   Condition:
//     rd_en && !empty
//
//   Behavior:
//     dout <= memory[read_ptr]
//     read_ptr++
//     count--
//
// Simultaneous Read and Write
//   Condition:
//     wr_en && rd_en && !full && !empty
//
//   Behavior:
//     memory[write_ptr] <= din
//     dout <= memory[read_ptr]
//     write_ptr++
//     read_ptr++
//     count remains unchanged
//
// Full Condition
//   - Ignore write request when full
//
// Empty Condition
//   - Ignore read request when empty
//
// Full + Read + Write
//   - Allow both operations
//   - count remains DEPTH
//   - read_ptr++
//   - write_ptr++
//
// Empty + Read + Write
//   - Current implementation:
//       * Perform write only
//       * Ignore read
//       * No bypass (FWFT not supported)
//==============================================================================

//
// Coding Style
//   - Sequential logic  : always_ff
//   - Combinational logic: always_comb
//   - Sequential assignment uses <=
//   - Combinational assignment uses =
//   - Parameters use parameter int
//   - Internal signals use logic
//
