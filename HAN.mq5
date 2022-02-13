//+------------------------------------------------------------------+
//|	     	                                                 HAN.mq5 |
//|                                                    Andriy Moraru |
//|                                         http://www.earnforex.com |
//|            							                       2013-2016 |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2013-2016"
#property link      "http://www.earnforex.com"
#property version   "1.01"

#property description "Uses Heiken Ashi candles."
#property description "Sells on bullish HA candle, its body is longer than previous body, previous also bullish, and current candle has no lower wick."
#property description "Buys on bearish HA candle, its body is longer than previous body, previous also bearish, and current candle has no upper wick."
#property description "Exit shorts on bearish HA candle and current candle has no upper wick, previous also bearish."
#property description "Exit longs on bullish HA candle and current candle has no lower wick, previous also bullish."

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

// Money management
input double Lots = 0.1; 		// Basic lot size.
input bool MM  = false;  	// MM - If true - ATR-based position sizing.
input int ATR_Period = 20;
input double ATR_Multiplier = 1;
input double Risk = 2; // Risk - Risk tolerance in percentage points.
input double FixedBalance = 0; // FixedBalance - If greater than 0, position size calculator will use it instead of actual account balance.
input double MoneyRisk = 0; // MoneyRisk - Risk tolerance in base currency.
input bool UseMoneyInsteadOfPercentage = false;
input bool UseEquityInsteadOfBalance = false;
input int LotDigits = 2; // LotDigits - How many digits after dot supported in lot size. For example, 2 for 0.01, 1 for 0.1, 3 for 0.001, etc.

// Miscellaneous
input string OrderComment = "HAN";
input int Slippage = 100; 	// Tolerated slippage in brokers' pips.

// Main trading objects
CTrade *Trade;
CPositionInfo PositionInfo;

// Global variables
// Common
ulong LastBars = 0;
bool HaveLongPosition;
bool HaveShortPosition;
double StopLoss; // Not actual stop-loss - just a potential loss of MM estimation.

// Indicator handles
int HeikenAshiHandle;
int ATRHandle;

// Buffers
double HAOpen[];
double HAClose[];
double HAHigh[];
double HALow[];

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
	// Initialize the Trade class object
	Trade = new CTrade;
	Trade.SetDeviationInPoints(Slippage);
	HeikenAshiHandle = iCustom(_Symbol, _Period, "Examples\\Heiken_Ashi");
   ATRHandle = iATR(NULL, 0, ATR_Period);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
	delete Trade;
}

//+------------------------------------------------------------------+
//| Expert Every Tick Function                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   if ((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) || (!TerminalInfoInteger(TERMINAL_CONNECTED)) || (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)) return;
	
	int bars = Bars(_Symbol, _Period);
	
	// Trade only if new bar has arrived
	if (LastBars != bars) LastBars = bars;
	else return;
	
   // Latest two completed bars
   if (CopyBuffer(HeikenAshiHandle, 0, 1, 2, HAOpen) != 2) return;
   if (CopyBuffer(HeikenAshiHandle, 3, 1, 2, HAClose) != 2) return;
   // Don't need the previous candle for High/Low, but copying it anyway for the sake of code uniformity.
   if (CopyBuffer(HeikenAshiHandle, 1, 1, 2, HAHigh) != 2) return;
   if (CopyBuffer(HeikenAshiHandle, 2, 1, 2, HALow) != 2) return;
   
   // Getting the potential loss value based on current ATR.
   if (MM)
   {
      double ATR[1];
      if (CopyBuffer(ATRHandle, 0, 1, 1, ATR) != 1) return;
      StopLoss = ATR[0] * ATR_Multiplier;
   }
   
   // Close conditions   
   bool BearishClose = false;
   bool BullishClose = false;
   
   // Signals
   bool Bullish = false;
   bool Bearish = false;

   // REVERSED!!!
   
   // Close signals
   // Bullish HA candle, current has no lower wick, previous also bullish
   if ((HAOpen[1] < HAClose[1]) && (HALow[1] == HAOpen[1]) && (HAOpen[0] < HAClose[0]))
   {
      BullishClose = true;
   }
   // Bearish HA candle, current has no upper wick, previous also bearish
   else if ((HAOpen[1] > HAClose[1]) && (HAHigh[1] == HAOpen[1]) && (HAOpen[0] > HAClose[0]))
   {
      BearishClose = true;
   }

   // Sell entry condition
   // Bullish HA candle, and body is longer than previous body, previous also bullish, current has no lower wick
   if ((HAOpen[1] < HAClose[1]) && (HAClose[1] - HAOpen[1] > MathAbs(HAClose[0] - HAOpen[0])) && (HAOpen[0] < HAClose[0]) && (HALow[1] == HAOpen[1]))
   {
      Bullish = false;
      Bearish = true;
   }
   // Buy entry condition
   // Bearish HA candle, and body is longer than previous body, previous also bearish, current has no upper wick
   else if ((HAOpen[1] > HAClose[1]) && (HAOpen[1] - HAClose[1] > MathAbs(HAClose[0] - HAOpen[0])) && (HAOpen[0] > HAClose[0]) && (HAHigh[1] == HAOpen[1]))
   {
      Bullish = true;
      Bearish = false;
   }
   else
   {
      Bullish = false;
      Bearish = false;
   }
   
   GetPositionStates();
   
   if ((HaveShortPosition) && (BearishClose)) ClosePrevious();
   if ((HaveLongPosition) && (BullishClose)) ClosePrevious();

   if (Bullish)
   {
      if (!HaveLongPosition) fBuy();
   }
   else if (Bearish)
   {
      if (!HaveShortPosition) fSell();
   }
}

//+------------------------------------------------------------------+
//| Check what position is currently open										|
//+------------------------------------------------------------------+
void GetPositionStates()
{
	// Is there a position on this currency pair?
	if (PositionInfo.Select(_Symbol))
	{
		if (PositionInfo.PositionType() == POSITION_TYPE_BUY)
		{
			HaveLongPosition = true;
			HaveShortPosition = false;
		}
		else if (PositionInfo.PositionType() == POSITION_TYPE_SELL)
		{ 
			HaveLongPosition = false;
			HaveShortPosition = true;
		}
	}
	else 
	{
		HaveLongPosition = false;
		HaveShortPosition = false;
	}
}

//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
void fBuy()
{
	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
	Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, LotsOptimized(), Ask, 0, 0, OrderComment);
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
void fSell()
{
	double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
	Trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, LotsOptimized(), Bid, 0, 0, OrderComment);
}

//+------------------------------------------------------------------+
//| Calculate position size depending on money management parameters.|
//+------------------------------------------------------------------+
double LotsOptimized()
{
	if (!MM) return (Lots);
	
   double Size, RiskMoney, PositionSize = 0;

   // If could not find account currency, probably not connected.
   if (AccountInfoString(ACCOUNT_CURRENCY) == "") return(-1);

   if (FixedBalance > 0)
   {
      Size = FixedBalance;
   }
   else if (UseEquityInsteadOfBalance)
   {
      Size = AccountInfoDouble(ACCOUNT_EQUITY);
   }
   else
   {
      Size = AccountInfoDouble(ACCOUNT_BALANCE);
   }
   
   if (!UseMoneyInsteadOfPercentage) RiskMoney = Size * Risk / 100;
   else RiskMoney = MoneyRisk;

   double UnitCost = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double TickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if ((StopLoss != 0) && (UnitCost != 0) && (TickSize != 0)) PositionSize = NormalizeDouble(RiskMoney / (StopLoss * UnitCost / TickSize), LotDigits);

   if (PositionSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) PositionSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   else if (PositionSize > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) PositionSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   return(PositionSize);
} 

//+------------------------------------------------------------------+
//| Close open position																|
//+------------------------------------------------------------------+
void ClosePrevious()
{
	for (int i = 0; i < 10; i++)
	{
		Trade.PositionClose(_Symbol, Slippage);
		if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
			Print("Position Close Return Code: ", Trade.ResultRetcodeDescription());
		else return;
	}
}
//+------------------------------------------------------------------+