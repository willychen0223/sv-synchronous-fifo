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
//     or wr_en && full && read_accept
//
// Write-only Behavior:
//    memory[write_ptr] <= din
//    write_ptr++
//    count++
//
//    Accepted simultaneous read/write:
//      count remains unchanged
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
//   - Ignore a write-only request when full
//   - If read and write are both requested while full, allow both operations
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

//==============================================================================
// Synchronous FIFO RTL
//==============================================================================


module fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 wr_en,
    input  logic                 rd_en,
    input  logic [WIDTH-1:0]     din,

    output logic [WIDTH-1:0]     dout,
    output logic                 full,
    output logic                 empty
);

    // DEPTH=1 時，$clog2(1)=0，不能宣告 [-1:0]
    localparam int PTR_WIDTH   = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    // count 必須能表示 0 到 DEPTH
    localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

    //--------------------------------------------------------------------------
    // Internal state
    //--------------------------------------------------------------------------

    logic [WIDTH-1:0] memory [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] write_ptr;
    logic [PTR_WIDTH-1:0] read_ptr;
    logic [COUNT_WIDTH-1:0] count; // $clog2功能是確認後面的變數需要幾個bit count需要的是0 1 2 3 .. depth , count需要能顯示depth+1個

    //--------------------------------------------------------------------------
    // Accepted operations
    //--------------------------------------------------------------------------
    
    logic write_accept;
    logic read_accept;

    // Read 只有在 FIFO 非空時才能成功
    assign read_accept = rd_en && !empty;

    // Write 在以下情況可以成功：
    // 1. FIFO 尚未滿
    // 2. FIFO 雖然滿了，但同一拍會成功 read
    assign write_accept = wr_en && (!full || read_accept);

    //--------------------------------------------------------------------------
    // Status flags
    //--------------------------------------------------------------------------

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    //--------------------------------------------------------------------------
    // Sequential logic
    //--------------------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout      <= '0;
            write_ptr <= '0;
            read_ptr  <= '0;
            count     <= '0;
        end
        else begin
            //------------------------------------------------------------------
            // Write operation
            //------------------------------------------------------------------

            if (write_accept) begin
                memory[write_ptr] <= din;

                if (write_ptr == DEPTH - 1)
                    write_ptr <= '0;
                else
                    write_ptr <= write_ptr + 1'b1;
              
            end
            //------------------------------------------------------------------
            // Read operation
            //------------------------------------------------------------------

            if (read_accept) begin
                dout <= memory[read_ptr];

                if (read_ptr == DEPTH - 1)
                    read_ptr <= '0;
                else
                    read_ptr <= read_ptr + 1'b1;
            end

            //------------------------------------------------------------------
            // Count update
            //------------------------------------------------------------------

            case ({write_accept, read_accept})

                // Write only
                2'b10: count <= count + 1'b1;

                // Read only
                2'b01: count <= count - 1'b1;

                // Both or neither:
                // count keeps its current value
                default: ;

            endcase

        end
    end

endmodule
