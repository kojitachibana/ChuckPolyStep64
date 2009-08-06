/*
 * ChucKPolyStep64 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option ) any later version.
 *
 * ChucKPolyStep64 is distributed in the hope that it will be useful,
 * but WITHIOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ChucKPolyStep64. if not, see <http:/www.gnu.org/licenses/>.
 *
 */
 
//params
"/chuck" => string prefix; //OSC Message prefix
0 => int start;            //sequencer staus
120 => float bpm;          //bpm
0 => int step;             //sequencer step
36 => int octave;          //octave
int pitch[7];              //pitch
200 => float duration;     //duration
int x, y, state;           //led position
int led [8][8];            //led

//Setup OSC
OscSend oscSender;
oscSender.setHost("localhost", 8080);

OscRecv oscReceiver;
8000 => oscReceiver.port;
oscReceiver.listen();

//Setup MIDI
MidiOut midiOutPort;
MidiMsg midiMessage;

if (!midiOutPort.open(0)) me.exit();
<<<"MIDI device:"+midiOutPort.num()+"->"+midiOutPort.name()>>>;

//Initialize LED(All Off)
setupPrefix();
clearAllLed();

//OSC Receive Event initialize
oscReceiver.event(prefix + "/press", "iii") @=> OscEvent oscReceiveEvent;



//Pitch initialize
for (0 => int i; i<6; i++) i => pitch[i];

//Main Loop.
while (true) {
    while (oscReceiveEvent.nextMsg() != 0) {
        oscReceiveEvent.getInt() => x;
        oscReceiveEvent.getInt() => y;
        oscReceiveEvent.getInt() => state;
        
        if (state == 1) {
            if (y > 0) {
                if (led[x][y] == 0) {
                    1 => led[x][y];
                    ledOut(x, y, 1);
                }
                else {
                    0 => led[x][y];
                    ledOut(x, y, 0);
                }
            }
            else {
                if (x == 0) {
                    if (start == 0) 1 => start;
                    else 0 => start;
                }
                else if (x == 2) {
                    12 -=> octave;
                    if (octave < 0) 0 => octave;
                }
                else if (x == 3) {
                    12 +=> octave;
                    if (octave > 127) 127 => octave;
                }
                else if (x == 4) {
                    10 -=> duration;
                }
                else if (x == 5) {
                    10 +=> duration;
                }
                else if (x == 6) {
                    2 -=> bpm;
                    if (bpm < 20) 20 => bpm;
                }
                else if (x == 7) {
                    2 +=> bpm;
                    if (bpm > 200) 200 => bpm;
                }
            }
        }
    }
    
    if (start == 1) {
        //MIDI Note Out
        for (0 => int i; i<8; i++) if (led[step%8][i] == 1) spork ~ noteOut(pitch[i-1]+octave, 100, duration);
        
        //Seq Step
        stepPositionLedOut(step%8, 255);
        bpm2Sec(bpm)::second => now;
        stepPositionLedOut(step%8, 0);
        
        for (0 => int i; i<8; i++) ledOut(step%8, i, led[step%8][i]);
        
        1 +=> step;
    }
    else bpm2Sec(bpm)::second => now;
}

fun float bpm2Sec(float bpm) {
    return (1.0 / (bpm / 60.0)) / 4;
}

fun void noteOut(int note, int velocity, float duration) {
    //Note ON
    144 => midiMessage.data1;
    note => midiMessage.data2;
    velocity => midiMessage.data3;
    midiOutPort.send(midiMessage);
    
    duration::ms => now;
    
    //Note Off
    128 => midiMessage.data1;
    note => midiMessage.data2;
    velocity => midiMessage.data3;
    midiOutPort.send(midiMessage);
}

fun void ledOut(int x, int y, int state) {
    oscSender.startMsg(prefix + "/led", "iii");
    x => oscSender.addInt;
    y => oscSender.addInt;
    state => oscSender.addInt;
}

fun void stepPositionLedOut(int col, int state) {
    oscSender.startMsg(prefix + "/led_col", "ii");
    col => oscSender.addInt;
    state => oscSender.addInt;
}

fun void clearAllLed() {
    oscSender.startMsg(prefix + "/clear", "i");
    0 => oscSender.addInt;
}

fun void setupPrefix() {
    oscSender.startMsg("/sys/prefix", "s");
    prefix => oscSender.addString;
}


