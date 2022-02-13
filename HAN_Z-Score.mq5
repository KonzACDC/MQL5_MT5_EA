//+------------------------------------------------------------------+
//|	     	                                         HAN_Z-Score.mq5 |
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
#property description "Z-Score optimization with file save/load."

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
input string OrderComment = "HAN_Z-Score";
input int Slippage = 100; 	// Tolerated slippage in brokers' pips.
input bool Mute = false;
input string FileName = "HAN_vt.dat";

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

// Trade virtualization for Z-Score optimization
struct virtual_trading
{
   bool               TradeBlock; // Blocks real trading, allowing virutal
   ENUM_POSITION_TYPE VirtualDirection;
   bool               VirtualOpen;
   double             VirtualOP; // Open price for virtual position
   long               BlockTicket; // Order number, after which real trading was blocked.
};
virtual_trading VirtualTrading;
int fh; // File handle for saving and loading virtual trading data

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
   
   // Virtual trading initialization
   VirtualTrading.TradeBlock = false;
   VirtualTrading.VirtualOpen = false;
   VirtualTrading.VirtualOP = 0;
   if (FileIsExist(FileName, FILE_COMMON)) LoadFile();
   fh = FileOpen(FileName, FILE_WRITE|FILE_BIN|FILE_COMMON);
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

   // Virtual trading - blocking trading following a profitable trade.
   // Positive Z-Score means that losers are likely to be followed by winners and vice versa.
   if (!VirtualTrading.TradeBlock)
   {
      // Looking back for 1 week, but in fact, 1 day would be enough
      HistorySelect(TimeCurrent() - 7 * 24 * 3600, TimeCurrent());
      ulong deal = HistoryDealsTotal();
      deal = HistoryDealGetTicket((int)deal - 1);
      if (deal > 0)
      {
         if (HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            if ((HistoryDealGetDouble(deal, DEAL_PROFIT) > 0) && (HistoryDealGetInteger(deal, DEAL_ORDER) != VirtualTrading.BlockTicket))
            {
               VirtualTrading.TradeBlock = true;
               VirtualTrading.BlockTicket = HistoryDealGetInteger(deal, DEAL_ORDER);
               SaveFile();
               if (!Mute) Print("Real trading blocked on: ", deal, " ", HistoryDealGetInteger(deal, DEAL_ENTRY), " ", HistoryDealGetDouble(deal, DEAL_PROFIT));
            }
         }
      }
   }

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
   if (VirtualTrading.TradeBlock) // Virtual Check
   {
      if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
         {
   			HaveLongPosition = true;
			   HaveShortPosition = false;
         }
         else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
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
      return;
   }

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

   if (VirtualTrading.TradeBlock) // Virtual Buy
   {
      VirtualTrading.VirtualDirection = POSITION_TYPE_BUY;
      VirtualTrading.VirtualOpen = true;
      VirtualTrading.VirtualOP = Ask;
      SaveFile();
      if (!Mute) Print("Entered Virtual Long at ", VirtualTrading.VirtualOP, ".");
      return;
   }

	Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, LotsOptimized(), Ask, 0, 0, OrderComment);
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
void fSell()
{
	double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   if (VirtualTrading.TradeBlock) // Virtual Sell
   {
      VirtualTrading.VirtualDirection = POSITION_TYPE_SELL;
      VirtualTrading.VirtualOpen = true;
      VirtualTrading.VirtualOP = Bid;
      SaveFile();
      if (!Mute) Print("Entered Virtual Short at ", VirtualTrading.VirtualOP, ".");
      return;
   }

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
   if (VirtualTrading.TradeBlock) // Virtual Exit
   {
      if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
         {
            double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
          	// We lost, so the virtual trading can be turned off.
          	if (Bid < VirtualTrading.VirtualOP) VirtualTrading.TradeBlock = false;
            if (!Mute) Print("Closed Virtual Long at ", Bid, " with Open at ", VirtualTrading.VirtualOP);
         }
         else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
         {
          	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
          	// We lost, so the virtual trading can be turned off.
            if (Ask > VirtualTrading.VirtualOP) VirtualTrading.TradeBlock = false;
            if (!Mute) Print("Closed Virtual Short at ", Ask, " with Open at ", VirtualTrading.VirtualOP);
         }
         VirtualTrading.VirtualDirection = -1;
         VirtualTrading.VirtualOpen = false;
         VirtualTrading.VirtualOP = 0;
         SaveFile();
      }
      return;
   }

	for (int i = 0; i < 10; i++)
	{
		Trade.PositionClose(_Symbol, Slippage);
		if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
			Print("Position Close Return Code: ", Trade.ResultRetcodeDescription());
		else return;
	}
}

//+------------------------------------------------------------------+
//| Saves Virtual Trading data to a file                             |
//+------------------------------------------------------------------+
void SaveFile()
{
   // Need it to overwrite the data, not to append it each time we save.
   FileSeek(fh, 0, SEEK_SET);
   FileWriteStruct(fh, VirtualTrading, sizeof(VirtualTrading));
}

//+------------------------------------------------------------------+
//| Loads Virtual Trading data from a file                           |
//+------------------------------------------------------------------+
void LoadFile()
{
   fh = FileOpen(FileName, FILE_READ|FILE_BIN|FILE_COMMON);
   if (fh == INVALID_HANDLE)
   {
      Print("Could not load virtual trading data: ", GetLastError());
      return;
   }
   FileReadStruct(fh, VirtualTrading, sizeof(VirtualTrading));
   Print("Loaded virtual trading data. TradeBlock = ", VirtualTrading.TradeBlock, " VirtualDirection = ", VirtualTrading.VirtualDirection, " VirtualOpen = ", VirtualTrading.VirtualOpen, " VirtualOP = ", VirtualTrading.VirtualOP, " BlockTicket = ", VirtualTrading.BlockTicket);
   FileClose(fh);
}

//+------------------------------------------------------------------+