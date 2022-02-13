//+------------------------------------------------------------------+
//|	     	                                   	  PersistentAnti.mq5 |
//|                                                    Andriy Moraru |
//|                                         http://www.earnforex.com |
//|            							                            2013 |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2013"
#property link      "http://www.earnforex.com"
#property version   "1.00"

#property description "Exploits persistent/anti-peristent trend trading."
#property description "Twist? Acts contrary!."
#property description "Looks up N past bars."
#property description "If at least 66% (empirical) of N bars followed previous bar's direction, we are in persistent mode."
#property description "If at least 66% of N bars went against previous bar's direction, we are in anti-persistent mode."
#property description "If we are in persistent mode - open opposite to previous bar or keep a position which is opposite to previous bar."
#property description "If we are in anti-persistent mode - open in direction of previous bar or keep a position which is in direction of previous bar."
#property description "Yes, we trade assuming a change in persistence."
#property description "Prone to weekend gaps."

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

// Main input parameters
input int N = 10; // How many bars to lookup to detect (anti-)persistence.
input double Ratio = 0.66; // How big should be the share of (anti-)persistent bars.
input bool Reverse = true; // If true, will trade inversely to calculated persistence data.

// Money management
input bool MM  = false;  	// Use Money Management
input double Lots = 0.1; 		// Basic lot size
input int Slippage = 100; 	// Tolerated slippage in brokers' pips
input double MaxPositionSize = 5.0; //Maximum size of the position allowed by broker

// Miscellaneous
input string OrderComment = "PersisteneceAnti";

// Main trading objects
CTrade *Trade;
CPositionInfo PositionInfo;

// Global variables
ulong LastBars = 0;
bool HaveLongPosition;
bool HaveShortPosition;

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
	// Initialize the Trade class object
	Trade = new CTrade;
	Trade.SetDeviationInPoints(Slippage);
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
	
	MqlRates rates[];
	int copied = CopyRates(NULL, 0, 1, N + 1, rates); // Starting from first completed bar. + 1 because need N bars plus one more to compare the last of N to it.
   if (copied <= 0) Print("Error copying price data ", GetLastError());
	
   int Persistence = 0;
   int Antipersistence = 0;
 
   // Cycle inside the N-bar range
   for (int i = 1; i <= N; i++) // i is always pointing at a bar inside N-range.
   {
      //string s;
      
      // Previous bar was bullish
      if (rates[i - 1].close > rates[i - 1].open)
      {
         // Current bar is bullish
         if (rates[i].close > rates[i].open)
         {
            Persistence++; 
            //s = "Persistent";
         }
         // Current bar is bearish
         else if (rates[i].close < rates[i].open)
         {
            Antipersistence++;
            //s = "Antipersistent";
         }
         //Print(rates[i].time, " Open: ", rates[i].open, " Close: ", rates[i].close, " ", s, " Previous - Bullish @ ", rates[i - 1].time);
      }
      // Previous bar was bearish
      else if (rates[i - 1].close < rates[i - 1].open)
      {
         // Current bar is bearish
         if (rates[i].close < rates[i].open)
         {
            Persistence++;
            //s = "Persistent";
         }
         // Current bar is bullish
         else if (rates[i].close > rates[i].open) 
         {
            Antipersistence++;
            //s = "Antipersistent";
         }
         //Print(rates[i].time, " Open: ", rates[i].open, " Close: ", rates[i].close, " ", s, " Previous - Bearish @ ", rates[i - 1].time);
      }
      // NOTE: If previous or current bar is flat, neither persistence or anti-persistence point is scored, 
      //       which means that we are more likely to stay out of the market.
   }

   //Print("P: ", IntegerToString(Persistence), " A: ", IntegerToString(Antipersistence), " Threshold: ", DoubleToString(Ratio * N), " Previous bar: ", rates[N].time, " Open: ", rates[N].open, " Close: ", rates[N].close);

   GetPositionStates();

   if (((Persistence > Ratio * N) && (Reverse)) || ((Antipersistence > Ratio * N) && (!Reverse)))
   {
      // If previous bar was bullish, go short. Remember: we are acting on the contrary!
      if (rates[N].close > rates[N].open)
      {
         if (HaveLongPosition) ClosePrevious();
         if (!HaveShortPosition) fSell();
      }
      // If previous bar was bearish, go long.
      else if (rates[N].close < rates[N].open) 
      {
         if (HaveShortPosition) ClosePrevious();
         if (!HaveLongPosition) fBuy();
      }
   }
   else if (((Persistence > Ratio * N) && (!Reverse)) || ((Antipersistence > Ratio * N) && (Reverse)))
   {
      // If previous bar was bullish, go long.
      if (rates[N].close > rates[N].open) 
      {
         if (HaveShortPosition) ClosePrevious();
         if (!HaveLongPosition) fBuy();
      }
      // If previous bar was bearish, go short.
      else if (rates[N].close < rates[N].open)
      {
         if (HaveLongPosition) ClosePrevious();
         if (!HaveShortPosition) fSell();
      }
   }
   // If no Persistence or Antipersistence is detected, just close current position.
   else if ((HaveLongPosition) || (HaveShortPosition)) ClosePrevious();
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
//| Calculate position size depending on money management				|
//+------------------------------------------------------------------+
double LotsOptimized()
{
	if (!MM) return (Lots);
	
	double TLots = NormalizeDouble((MathFloor(AccountInfoDouble(ACCOUNT_BALANCE) * 1.5 / 1000)) / 10, 1); 
	
	int NO = 0;
	if (TLots < 0.1) return(0);
	if (TLots > MaxPositionSize) TLots = MaxPositionSize;

   return(TLots);
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

