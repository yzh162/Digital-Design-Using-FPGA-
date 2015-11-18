`timescale 1ns / 1ps

module Project(USER_CLK, GPIO_LED, GPIO_DIP_SW, PIEZO_SPEAKER);

    parameter    NoteC   = 11237;
    parameter    NoteD   = 12613;
    parameter    NoteE   = 14157;
    parameter    NoteFS  = 15891;
    parameter    NoteG   = 16836;
    parameter    NoteA   = 18898;
    parameter    NoteB   = 21212;
    parameter    NoteD5  = 25225;

    parameter  BeatSpeed1   = 23'b110_1100_0000_0000_0000_0000;  //  regular speed
    parameter  BeatSpeed2   = 23'b011_0110_0000_0000_0000_0000;  //   slow  speed

    input               USER_CLK;    // USER_CLK
    output reg [8:0]    GPIO_LED;    // LED light
    input      [7:0]    GPIO_DIP_SW;   // [7:4] stop sound, [3:0] adjust rythm of sound
    output reg          PIEZO_SPEAKER; 
   
    reg        [31:0]   Ctr;           // Accumulator, piezo follows Ctr[31]
    reg        [23:0]   BeatDuration;  // To adjust duration of each note (up ctr)
    reg        [23:0]   BeatSpeed;
    reg        [3:0]    BeatCtr;       // Counter for the notes (up counter)
    reg        [17:0]   CurrentNote;   // What note is being played ?  0 = none
    reg                 Activate;      // Used to activate / deactivate 
    reg        [3:0]    State_machine;  // Statemachine

    always @(posedge USER_CLK) 
    begin
              // Any button pushed activates the song
    if(Activate) 
    begin
      if(GPIO_DIP_SW[7] || GPIO_DIP_SW[6] || GPIO_DIP_SW[5] || GPIO_DIP_SW[4] == 1)
        Activate <= 0;  // stop working when either of switches[7:4] to be 1
    end 
    else    // when Activate=0 
    begin       
        Activate <= 1;  //  when SW[7:4] = 0, working
        BeatCtr <= 0;
    end
  
        
        if(GPIO_DIP_SW[3] || GPIO_DIP_SW[2] || GPIO_DIP_SW[1] || GPIO_DIP_SW[0] == 1) 
             BeatSpeed <= BeatSpeed1;
        else BeatSpeed <= BeatSpeed2;
      
    // Update BeatCtr by using the BeatDuration counter
    if(BeatDuration == BeatSpeed) 
        begin
          BeatDuration <= 0;
          if (Activate) BeatCtr <= BeatCtr + 1;          
        end 
      else begin
        if (Activate) BeatDuration <= BeatDuration+1;   
      end
    
    // Based on the current note we are playing, update "CurrentNote"
    case(BeatCtr)
      1:   begin   State_machine <= 4'b0001;     end
      2:   begin   State_machine <= 4'b0010;     end
      3:   begin   State_machine <= 4'b0011;     end
      4:   begin   State_machine <= 4'b0100;     end
      5:   begin   State_machine <= 4'b0101;     end
      6:   begin   State_machine <= 4'b0110;     end
      7:   begin   State_machine <= 4'b0111;     end
      8:   begin   State_machine <= 4'b1000;     end
      
      default: begin    BeatCtr <= 1; end
      // when BeatCtr=9, currentnote=noteC, 
    endcase
  end

always @(State_machine)
begin
case(State_machine)
4'b0001: GPIO_LED <= 8'b00000001; 
4'b0010: GPIO_LED <= 8'b00000010;
4'b0011: GPIO_LED <= 8'b00000100; 
4'b0100: GPIO_LED <= 8'b00001000; 
4'b0101: GPIO_LED <= 8'b00010000;
4'b0110: GPIO_LED <= 8'b00100000; 
4'b0111: GPIO_LED <= 8'b01000000;  
4'b1000: GPIO_LED <= 8'b10000000; 
default: GPIO_LED <= 8'b00000001; 
endcase

end

always @(State_machine)
begin
case(State_machine)
4'b0001: CurrentNote <= NoteC; 
4'b0010: CurrentNote <= NoteD;
4'b0011: CurrentNote <= NoteE; 
4'b0100: CurrentNote <= NoteFS; 
4'b0101: CurrentNote <= NoteG;
4'b0110: CurrentNote <= NoteA; 
4'b0111: CurrentNote <= NoteB;  
4'b1000: CurrentNote <= NoteD5; 
default: CurrentNote <= NoteC; 
endcase

Ctr <= Ctr+CurrentNote;  // Update the counter and feed PIEZO_SPEAKER from Ctr[31]
PIEZO_SPEAKER <= Ctr[31];
end

endmodule

