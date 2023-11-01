#include <xs1.h>
#include <stdio.h>
#include <xclib.h>
#include <platform.h>
#include <print.h>
#include "xassert.h"
#include "spdif.h"
#include "adat_tx.h"

on tile[1]: out buffered    port:32 p_opt_tx        = XS1_PORT_1G;
on tile[1]: out buffered    port:32 p_coax_tx       = XS1_PORT_1A;
on tile[1]: in              port    p_mclk_in       = XS1_PORT_1D;
on tile[1]: clock                   clk_audio       = XS1_CLKBLK_1;

// Optional if required for board setup.
on tile[0]: out             port    p_ctrl          = XS1_PORT_8D;
on tile[0]: in              port    p_but           = XS1_PORT_4E;
on tile[0]: out             port    p_leds          = XS1_PORT_4F;

// Found solution: IN 24.000MHz, OUT 24.576000MHz, VCO 2457.60MHz, RD 1, FD 102.400 (m = 2, n = 5), OD 5, FOD 5, ERR 0.0ppm
#define APP_PLL_CTL_24M  0x0A006500
#define APP_PLL_DIV_24M  0x80000004
#define APP_PLL_FRAC_24M 0x80000104

//Found solution: IN 24.000MHz, OUT 22.579186MHz, VCO 3522.35MHz, RD  1, FD  146.765 (m =  13, n =  17), OD  3, FOD   13, ERR -0.641ppm
#define APP_PLL_CTL_22M  0x09009100
#define APP_PLL_DIV_22M  0x8000000C
#define APP_PLL_FRAC_22M 0x80000C10

#define MCLK_FREQUENCY_441  22579200
#define MCLK_FREQUENCY_48   24576000

#define SINE_TABLE_SIZE 96

// One cycle of full scale 24 bit sine wave in 96 samples.
// This will produce 500Hz signal at Fs = 48kHz, 1kHz at 96kHz and 2kHz at 192kHz.
const int32_t sine_table1[96] =
{
    0x000000,0x085F21,0x10B515,0x18F8B8,0x2120FB,0x2924ED,0x30FBC5,0x389CEA,
    0x3FFFFF,0x471CEC,0x4DEBE4,0x546571,0x5A8279,0x603C49,0x658C99,0x6A6D98,
    0x6ED9EB,0x72CCB9,0x7641AE,0x793501,0x7BA374,0x7D8A5E,0x7EE7A9,0x7FB9D6,
    0x7FFFFF,0x7FB9D6,0x7EE7A9,0x7D8A5E,0x7BA374,0x793501,0x7641AE,0x72CCB9,
    0x6ED9EB,0x6A6D98,0x658C99,0x603C49,0x5A8279,0x546571,0x4DEBE4,0x471CEC,
    0x3FFFFF,0x389CEA,0x30FBC5,0x2924ED,0x2120FB,0x18F8B8,0x10B515,0x085F21,
    0x000000,0xF7A0DF,0xEF4AEB,0xE70748,0xDEDF05,0xD6DB13,0xCF043B,0xC76316,
    0xC00001,0xB8E314,0xB2141C,0xAB9A8F,0xA57D87,0x9FC3B7,0x9A7367,0x959268,
    0x912615,0x8D3347,0x89BE52,0x86CAFF,0x845C8C,0x8275A2,0x811857,0x80462A,
    0x800001,0x80462A,0x811857,0x8275A2,0x845C8C,0x86CAFF,0x89BE52,0x8D3347,
    0x912615,0x959268,0x9A7367,0x9FC3B7,0xA57D87,0xAB9A8F,0xB2141C,0xB8E314,
    0xC00001,0xC76316,0xCF043B,0xD6DB13,0xDEDF05,0xE70748,0xEF4AEB,0xF7A0DF
};

// Two cycles of full scale 24 bit sine wave in 96 samples.
// This will produce 1kHz signal at Fs = 48kHz, 2kHz at 96kHz and 4kHz at 192kHz.
const int32_t sine_table2[96] =
{
    0x000000,0x10B515,0x2120FB,0x30FBC5,0x3FFFFF,0x4DEBE4,0x5A8279,0x658C99,
    0x6ED9EB,0x7641AE,0x7BA374,0x7EE7A9,0x7FFFFF,0x7EE7A9,0x7BA374,0x7641AE,
    0x6ED9EB,0x658C99,0x5A8279,0x4DEBE4,0x3FFFFF,0x30FBC5,0x2120FB,0x10B515,
    0x000000,0xEF4AEB,0xDEDF05,0xCF043B,0xC00001,0xB2141C,0xA57D87,0x9A7367,
    0x912615,0x89BE52,0x845C8C,0x811857,0x800001,0x811857,0x845C8C,0x89BE52,
    0x912615,0x9A7367,0xA57D87,0xB2141C,0xC00001,0xCF043B,0xDEDF05,0xEF4AEB,
    0x000000,0x10B515,0x2120FB,0x30FBC5,0x3FFFFF,0x4DEBE4,0x5A8279,0x658C99,
    0x6ED9EB,0x7641AE,0x7BA374,0x7EE7A9,0x7FFFFF,0x7EE7A9,0x7BA374,0x7641AE,
    0x6ED9EB,0x658C99,0x5A8279,0x4DEBE4,0x3FFFFF,0x30FBC5,0x2120FB,0x10B515,
    0x000000,0xEF4AEB,0xDEDF05,0xCF043B,0xC00001,0xB2141C,0xA57D87,0x9A7367,
    0x912615,0x89BE52,0x845C8C,0x811857,0x800001,0x811857,0x845C8C,0x89BE52,
    0x912615,0x9A7367,0xA57D87,0xB2141C,0xC00001,0xCF043B,0xDEDF05,0xEF4AEB
};

// Set secondary (App) PLL control register through essential mechanism.
void set_app_pll_init (tileref tile, int app_pll_ctl)
{
    // delay_microseconds(500);
    // Disable the PLL
    write_node_config_reg(tile, XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (app_pll_ctl & 0xF7FFFFFF));
    // Enable the PLL to invoke a reset on the appPLL.
    write_node_config_reg(tile, XS1_SSWITCH_SS_APP_PLL_CTL_NUM, app_pll_ctl);
    // Must write the CTL register twice so that the F and R divider values are captured using a running clock.
    write_node_config_reg(tile, XS1_SSWITCH_SS_APP_PLL_CTL_NUM, app_pll_ctl);
    // Now disable and re-enable the PLL so we get the full 5us reset time with the correct F and R values.
    write_node_config_reg(tile, XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (app_pll_ctl & 0xF7FFFFFF));
    write_node_config_reg(tile, XS1_SSWITCH_SS_APP_PLL_CTL_NUM, app_pll_ctl);
    // Wait for PLL to lock.
    delay_microseconds(500);
}

void app_pll_setup(unsigned samp_rate)
{
    if ((samp_rate % 44100) == 0)
    {
        set_app_pll_init(tile[0], APP_PLL_CTL_22M);
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_22M);
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_CLK_DIVIDER_NUM, APP_PLL_DIV_22M);
    }
    else
    {
        set_app_pll_init(tile[0], APP_PLL_CTL_24M);
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_24M);
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_CLK_DIVIDER_NUM, APP_PLL_DIV_24M);
    }
    delay_milliseconds(10);
}

unsigned adatSamplesToSend[8];

void generate_samples(chanend c_spdif, chanend c_adat, chanend c_in)
{
    unsigned currentFreq = 44100;
    unsigned mclk = MCLK_FREQUENCY_441;
    int i = 0;
    app_pll_setup(currentFreq);
    spdif_tx_reconfigure_sample_rate(c_spdif, currentFreq, mclk);

    int adatSmuxMode = currentFreq/44100;
    int adatMultiple = mclk/44100;
    unsigned adatSamples[8];

    int adatCounter = 0;

    for(int i = 0; i < 8; i++)
        adatSamples[i]=0;

    outuint(c_adat, adatMultiple);
    outuint(c_adat, adatSmuxMode);

    unsafe
    {
        volatile unsigned * unsafe samplePtr = (unsigned * unsafe) &adatSamples;
        outuint(c_adat, (unsigned) samplePtr);
    }

    while(1)
    {
        select
        {
            case c_in :> currentFreq: // Get new SR from channel

                adatCounter = 0;

                if ((currentFreq % 44100) == 0)
                {
                    mclk = MCLK_FREQUENCY_441;
                    adatSmuxMode = currentFreq/44100;
                    adatMultiple = mclk/44100;
                }
                else
                {
                    mclk = MCLK_FREQUENCY_48;
                    adatSmuxMode = currentFreq/48000;
                    adatMultiple = mclk/48000;
                }
                app_pll_setup(currentFreq);
                spdif_tx_reconfigure_sample_rate(c_spdif, currentFreq, mclk);

                inuint(c_adat);

                outct(c_adat, XS1_CT_END);
                outuint(c_adat, adatMultiple);
                outuint(c_adat, adatSmuxMode);
                printintln(adatSmuxMode);
                unsafe
                {
                    volatile unsigned * unsafe samplePtr = (unsigned * unsafe) &adatSamples;
                    outuint(c_adat, (unsigned) samplePtr);
                }

                i = 0;
                break;

            default:
                // Generate a sine wave
                int sample_l = sine_table1[i] << 8;
                int sample_r = sine_table2[i] << 8; // Twice the frequency on right channel.
                i = (i + 1) % SINE_TABLE_SIZE;

                /* Transfer S/PDIF samples */
                spdif_tx_output(c_spdif, sample_l, sample_r);

                /* Transfer ADAT samples - put sine waves on channels 0/1 */
                adatSamples[0] = sample_l;
                adatSamples[1] = sample_r;

                /* Do some rearranging for SMUX */
                /* Note, when smux == 1 this loop just does a straight 1:1 copy */
                //if(smux != 1)
                {
                    int adatSampleIndex = adatCounter;
                    for(int i = 0; i < (8/adatSmuxMode); i++)
                    {
                        adatSamplesToSend[adatSampleIndex] = adatSamples[i];
                        adatSampleIndex += adatSmuxMode;
                    }
                }

                adatCounter++;
                if(adatCounter == adatSmuxMode)
                {
                    unsafe
                    {
                        /* Wait for adat to be done with previous buffer */
                        inuint(c_adat);
                        volatile unsigned * unsafe samplePtr = (unsigned * unsafe) &adatSamplesToSend;
                        outuint(c_adat, (unsigned) samplePtr);
                    }
                    adatCounter = 0;
                }

                break;
        }
    }
}

void led_flash(unsigned flashcount)
{
    for(int i = 0; i < flashcount; i++)
    {
        // Light LEDs
        p_leds <: 0xF;
        delay_milliseconds(200);
        // Turn LEDs off.
        p_leds <: 0x0;
        delay_milliseconds(200);
    }
}

void board_setup_control(chanend c_out)
{
    //////// BOARD SETUP FOR XU316 MC AUDIO ////////

    //set_port_drive_high(p_ctrl);

    // Drive control port to turn on 3V3.
    // Bits set to low will be high-z, pulled down.
    p_ctrl <: 0xA0;

    // Wait for power supplies to be up and stable.
    delay_milliseconds(10);
#define EXT_PLL_SEL__MCLK_DIR    (0x80)
   for (int i = 0; i < 30; i++)
     {
         p_ctrl <: EXT_PLL_SEL__MCLK_DIR | 0x30; /* 3v3: off, 3v3A: on */
         delay_microseconds(5);
         p_ctrl <: EXT_PLL_SEL__MCLK_DIR | 0x20; /* 3v3: on, 3v3A: on */
         delay_microseconds(5);
     }

    unsigned currentFreq = 44100;
    c_out <: currentFreq;
    unsigned tmp;

    while(1)
    {
        /* Change sample frequency */
        p_but :> tmp;
        tmp = ~tmp;
        if (tmp & 1) // Button 0 Pressed
        {
            while (tmp & 0x01) {p_but :> tmp;}
            //printstr("Time to switch\n");
            switch(currentFreq)
            {
                case 44100:  led_flash(2); currentFreq = 48000; break;
                case 48000:  led_flash(3); currentFreq = 88200; break;
                case 88200:  led_flash(4); currentFreq = 96000; break;
                case 96000:  led_flash(5); currentFreq = 176400; break;
                case 176400: led_flash(6); currentFreq = 192000; break;
                case 192000: led_flash(1); currentFreq = 44100; break;
                default:     led_flash(2); currentFreq = 48000; break;
            }
            printintln(currentFreq);
            c_out <: currentFreq;
            delay_milliseconds(100);
        }
    }
}

int main(void) {
    chan c_spdif;
    chan c_control;
    chan c_adat;
    par
    {
        on tile[0]: board_setup_control(c_control);
        on tile[1]:
        {
            spdif_tx_port_config(p_coax_tx, clk_audio, p_mclk_in, 7);

            configure_out_port_no_ready(p_opt_tx, clk_audio, 0);

            start_clock(clk_audio);

            par
            {
                spdif_tx(p_coax_tx, c_spdif);
                while(1)
                    adat_tx_port(c_adat, p_opt_tx);
            }
        }
        on tile[1]: generate_samples(c_spdif, c_adat, c_control);
    }
    return 0;
}
