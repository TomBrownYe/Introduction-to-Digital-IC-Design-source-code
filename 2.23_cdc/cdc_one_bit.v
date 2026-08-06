module cdc_one_bit(
    input clk1,
    input clk2,
    
    input rst1_n,
    input rst2_n,

    input a,

    output b,
    output busy
);

reg a_latch;
reg b_latch;
reg b_latch_r;
reg b_latch_2r;
reg b_feedback_latch;
reg c_latch;
reg c_latch_r;

always@(posedge clk1 or negedge rst1_n)begin
    if(!rst1_n)begin
        a_latch <= 1'b0;
    end
    else if(a)begin            
        a_latch <= 1'b1;             //先在clk1域把a变成电平
    end
    else if (c_latch_r)begin         //当目的时钟域反馈称脉冲b已产生，本电平会归零
        a_latch <= 1'b0;
    end
end

always@(posedge clk2 or negedge rst2_n)begin
    if(!rst2_n)begin
        b_latch <= 1'b0;
        b_latch_r <= 1'b0;
        b_latch_2r <= 1'b0;
    end
    else begin
        b_latch <= a_latch;           //跨时钟第一拍，容易产生亚稳态
        b_latch_r <= b_latch;         //跨时钟第二拍，几乎没有亚稳态
        b_latch_2r <= b_latch_r;      //为了转换为脉冲而打拍
    end
end

assign b = b_latch_r & (~b_latch_2r); //抓取b_latch_r的上升脉冲

always@(posedge clk2 or negedge rst2_n)begin
    if(!rst2_n)begin
        b_feedback_latch <= 1'b0;
    end
    else if(b)begin
        //反馈信号，当b起来以后它也锁存住
        b_feedback_latch <= 1'b1;
    end
    else if(~b_latch_r)begin  //“~”和“！”的区别：前者是按位取反，后者是逻辑取反，对于单比特是可以混用的
        //当源时钟的电平已归零后，反馈电平也归零
        b_feedback_latch <= 1'b0;
    end
end

always@(posedge clk1 or negedge rst1_n)begin
    if(!rst1_n)begin
        c_latch <= 1'b0;               //跨时钟第一拍，容易产生亚稳态
        c_latch_r <= 1'b0;             //跨时钟第二拍，几乎没有亚稳态
    end
    else begin
        c_latch <= b_feedback_latch;
        c_latch_r <= c_latch;
    end
end

assign busy = a_latch | c_latch_r;     //产生忙信号阻止新的握手请求

endmodule