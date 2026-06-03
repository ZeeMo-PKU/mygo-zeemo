// rtl/sorting_engine.sv
module sorting_engine #(
    parameter int N = 8,
    parameter int WIDTH = 8
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     start,
    input  logic [N*WIDTH-1:0]       in_data,
    output logic                     done,
    output logic [N*WIDTH-1:0]       out_data
);

    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        SORTING,
        DONE
    } state_t;

    state_t state;

    logic [WIDTH-1:0] arr [0:N-1];          // internal array storage
    logic [$clog2(N)-1:0] pass;            // pass counter (0 .. N-1)
    logic [$clog2(N)-1:0] j;               // inner loop counter (0 .. N-2)

    // FSM and data‑path
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            done     <= 1'b0;
            out_data <= '0;          // clear output (can be left uninitialized)
            for (int i = 0; i < N; i++)
                arr[i] <= '0;
            pass <= '0;
            j    <= '0;
        end else begin
            done <= 1'b0;            // default, overridden in DONE state
            case (state)
                IDLE: begin
                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    // capture input data
                    for (int i = 0; i < N; i++)
                        arr[i] <= in_data[i*WIDTH +: WIDTH];
                    pass <= '0;
                    j    <= '0;
                    if (N > 1)
                        state <= SORTING;
                    else
                        state <= DONE;   // trivial case N=1
                end

                SORTING: begin
                    if (N > 1) begin
                        // compare and conditionally swap adjacent elements
                        if (arr[j] > arr[j+1]) begin
                            arr[j]   <= arr[j+1];
                            arr[j+1] <= arr[j];
                        end

                        // update counters and control
                        if (j == (N-2)) begin
                            j <= '0;
                            if (pass == (N-1)) begin     // all passes completed
                                state <= DONE;
                            end else begin
                                pass <= pass + 1;
                            end
                        end else begin
                            j <= j + 1;
                        end
                    end else begin
                        state <= DONE;   // should never be reached when N=1
                    end
                end

                DONE: begin
                    done <= 1'b1;
                    // pack sorted array into output bus
                    for (int i = 0; i < N; i++)
                        out_data[i*WIDTH +: WIDTH] <= arr[i];
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule