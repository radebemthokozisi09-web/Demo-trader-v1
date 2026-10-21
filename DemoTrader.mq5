//+------------------------------------------------------------------+
//| DEMO TRADER v1                                                  |
//| MT5 Expert Advisor - Development Starter                        |
//| Live trading must remain disabled during initial testing.       |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"
#property description "Demo Trader MT5 development starter"

#include <Trade/Trade.mqh>

CTrade trade;

//--- Adjustable settings
input double FixedLotSize       = 0.01;
input int    FastEMA            = 9;
input int    SlowEMA            = 21;
input int    ATRPeriod          = 14;
input double StopLossATR        = 1.5;
input double TakeProfitRR       = 3.0;
input ulong  MagicNumber        = 210001;
input bool   EnableLiveTrading  = false;

//--- Indicator handles
int fastHandle = INVALID_HANDLE;
int slowHandle = INVALID_HANDLE;
int atrHandle  = INVALID_HANDLE;

datetime lastBarTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   if(FixedLotSize <= 0 ||
      FastEMA <= 0 ||
      SlowEMA <= FastEMA ||
      ATRPeriod <= 0 ||
      StopLossATR <= 0 ||
      TakeProfitRR <= 0)
   {
      Print("Invalid settings. Check inputs.");
      return INIT_PARAMETERS_INCORRECT;
   }

   fastHandle = iMA(_Symbol, PERIOD_CURRENT,
                    FastEMA, 0, MODE_EMA, PRICE_CLOSE);

   slowHandle = iMA(_Symbol, PERIOD_CURRENT,
                    SlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);

   if(fastHandle == INVALID_HANDLE ||
      slowHandle == INVALID_HANDLE ||
      atrHandle == INVALID_HANDLE)
   {
      Print("Indicator initialization failed.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);

   Print("DEMO TRADER initialized on ", _Symbol,
         ". Live trading setting: ", EnableLiveTrading);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(fastHandle != INVALID_HANDLE)
      IndicatorRelease(fastHandle);

   if(slowHandle != INVALID_HANDLE)
      IndicatorRelease(slowHandle);

   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Safety lock: no orders can be sent in this starter version.
   if(!EnableLiveTrading)
      return;

   // Evaluate once per new candle.
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar == 0 || currentBar == lastBarTime)
      return;

   lastBarTime = currentBar;

   // Do not open another position on this symbol.
   if(PositionSelect(_Symbol))
      return;

   double fast[3], slow[3], atr[3];

   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(fastHandle, 0, 0, 3, fast) < 3 ||
      CopyBuffer(slowHandle, 0, 0, 3, slow) < 3 ||
      CopyBuffer(atrHandle, 0, 0, 3, atr) < 3)
   {
      Print("Waiting for indicator data.");
      return;
   }

   // Use completed candles only.
   bool buySignal =
      fast[2] <= slow[2] &&
      fast[1] > slow[1];

   bool sellSignal =
      fast[2] >= slow[2] &&
      fast[1] < slow[1];

   if(!buySignal && !sellSignal)
      return;

   MqlTick tick;

   if(!SymbolInfoTick(_Symbol, tick) || atr[1] <= 0)
      return;

   double volume = FixedLotSize;

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Never silently increase the requested lot size.
   if(volume < minLot || volume > maxLot ||
      lotStep <= 0 ||
      MathAbs(volume / lotStep -
              MathRound(volume / lotStep)) > 0.000001)
   {
      Print("Lot size is invalid for this symbol. No trade.");
      return;
   }

   double stopDistance = atr[1] * StopLossATR;
   double targetDistance = stopDistance * TakeProfitRR;

   double sl = 0;
   double tp = 0;
   bool result = false;

   if(buySignal)
   {
      sl = NormalizeDouble(tick.ask - stopDistance, _Digits);
      tp = NormalizeDouble(tick.ask + targetDistance, _Digits);

      result = trade.Buy(volume, _Symbol, 0, sl, tp,
                         "DemoTrader EMA Buy");
   }
   else if(sellSignal)
   {
      sl = NormalizeDouble(tick.bid + stopDistance, _Digits);
      tp = NormalizeDouble(tick.bid - targetDistance, _Digits);

      result = trade.Sell(volume, _Symbol, 0, sl, tp,
                          "DemoTrader EMA Sell");
   }

   if(!result)
      Print("Order rejected or failed: ", trade.ResultRetcode(),
            " - ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+