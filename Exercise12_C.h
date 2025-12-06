/*********************************************************************/
/* Lab Exercise Twelve                                               */
/* A game that is played using the terminal and the LED on the KLO5  */
/* board. The LED will flash a color and the objective is for the    */
/* user to enter the first letter of the color before a timer runs   */
/* out. The amount of time alloted to enter the character decreases  */
/* every round.                                                      */
/* Name:  Richard Bradley Wilkinson & Frank Zou                      */
/* Date:  December 3, 2024                                           */
/* Class:  CMPE 250                                                  */
/* Section:  Lab02                                                   */
/*********************************************************************/

#define EXERCISE_12_C (1)

typedef int Int32;
typedef short int Int16;
typedef char Int8;
typedef unsigned int UInt32;
typedef unsigned short int UInt16;
typedef unsigned char UInt8;

/* assembly language subroutines */
char GetChar (void);
void GetStringSB (char String[], int StringBufferCapacity);
void Init_UART0_IRQ (void);
void Init_PIT_IRQ (void);
void PutChar (char Character);
void PutNumHex (UInt32);
void PutNumUB (UInt8);
void PutStringSB (char String[], int StringBufferCapacity);
int	ReturnCount	(void);
void ClearCount (void);
int	CheckRxQueue	(void);
