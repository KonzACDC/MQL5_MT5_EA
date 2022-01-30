//+------------------------------------------------------------------+
//|                                                   exp_multic.mq5 |
//|                                      Copyright 2012-2016, DC2008 |
//|                              http://www.mql5.com/ru/users/dc2008 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012-2016, DC2008"
#property link      "http://www.mql5.com/ru/users/dc2008"
#property version   "1.00"
#property description   "Expert implements the strategy of multi-currency trading"
#property description   "without using technical analysis indicators"
//---
#include <Trade\Trade.mqh>
//---
#define EURUSD      "EURUSD"
#define GBPUSD      "GBPUSD"
#define USDJPY      "USDJPY"
#define USDCHF      "USDCHF"
#define USDCAD      "USDCAD"
#define AUDUSD      "AUDUSD"
#define EURGBP      "EURGBP"
#define EURJPY      "EURJPY"
#define EURAUD      "EURAUD"
#define GBPJPY      "GBPJPY"
//---
MqlTick last_tick;
CTrade  trade;
//---
input int      loss=1900;   // ������ � ������ ��������
input int      profit=4000; // ������� � ������ ��������
input int      margin=5000; // ����������� ������ ��������, ��� ������� �������� ��������
input double   minLot=0.01; // ����������� ����� �������
input int      k_change=2100; // ����������� ��� ������� ������ ��� ��������� �������
input int      k_closse=4600; // ����������� ��� ������� ������� ��� �������� �������
//---
string  valuta[10]=
  {
   EURUSD,
   GBPUSD,
   USDJPY,
   USDCHF,
   USDCAD,
   AUDUSD,
   EURGBP,
   EURJPY,
   EURAUD,
   GBPJPY
  };
int      N;          // ���������� �������� ���
bool     Type[10];   // ����������� �������� ��� ������ �������� ����: BUY ��� SELL
double   Lot[10];    // ������ ���� ��� ������ �������� ����
string   main_comment;  // ������ �����������
bool     on_trade;      // ��������� ��� ��������� ��������
double   realEquity;    // ��������� ������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Comment("");
   realEquity=AccountInfoDouble(ACCOUNT_BALANCE);
   main_comment="exp_multic: ";
   N=ArraySize(valuta);
   on_trade=true;
   for(int i=0;i<N; i++)
     {
      Type[i]=true;
      Lot[i]=minLot;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double Balans=AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double FreeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   Comment("��������� ������: ",NormalizeDouble(realEquity,2),
           "\n","������� ������: ",NormalizeDouble(Balans,2),
           "\n","��������� �������� ������: ",NormalizeDouble(Balans-realEquity,2));
//---
   if(Balans-Equity>loss) on_trade=false;    // ��� ���������� ��������� ������ ��� ������� �����������
   if(Equity-Balans>profit) on_trade=false;  // ��� ���������� �������� ������� ��� ������� �����������
//--- �������� ���� ������� �������������
   if(!on_trade)
     {
      for(int i=0;i<N; i++)
        {
         trade.PositionClose(valuta[i]);
         Lot[i]=minLot;
        }
      on_trade=true;
     }
//---
   if(on_trade)
     {
      for(int i=0;i<N; i++)
        {
         if(PositionSelect(valuta[i]))
           {
            //--- ���� ������� ����������, �� ���������� �����
            if(PositionGetDouble(POSITION_PROFIT)>Lot[i]*k_change)
              {
               Lot[i]=Lot[i]+minLot;
               double lot=minLot;
               if(Type[i])
                 {
                  SymbolInfoTick(valuta[i],last_tick);
                  double price=last_tick.ask;
                  trade.PositionOpen(valuta[i],ORDER_TYPE_BUY,NormalizeDouble(lot,2),price,0,0,main_comment+valuta[i]);
                 }
               else
                 {
                  SymbolInfoTick(valuta[i],last_tick);
                  double price=last_tick.bid;
                  trade.PositionOpen(valuta[i],ORDER_TYPE_SELL,NormalizeDouble(lot,2),price,0,0,main_comment+valuta[i]);
                 }
              }
            //--- ���� ������� ���������, �� ��������� � � ��� ������� �� ��������
            if(PositionGetDouble(POSITION_PROFIT)<-Lot[i]*k_change)
              {
               Type[i]=!Type[i];
               trade.PositionClose(valuta[i]);
              }
            //--- ��������� ���������� �������
            if(PositionGetDouble(POSITION_PROFIT)>minLot*k_closse)
               trade.PositionClose(valuta[i]);

           }
         //--- �������� ����� �������
         if(!PositionSelect(valuta[i]) && FreeMargin>margin)
           {
            Lot[i]=minLot;
            double lot=minLot;
            if(Type[i])
              {
               SymbolInfoTick(valuta[i],last_tick);
               double price=last_tick.ask;
               trade.PositionOpen(valuta[i],ORDER_TYPE_BUY,NormalizeDouble(lot,2),price,0,0,main_comment+valuta[i]);
              }
            else
              {
               SymbolInfoTick(valuta[i],last_tick);
               double price=last_tick.bid;
               trade.PositionOpen(valuta[i],ORDER_TYPE_SELL,NormalizeDouble(lot,2),price,0,0,main_comment+valuta[i]);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
