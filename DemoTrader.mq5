 //+------------------------------------------------------------------+
//| DEMO TRADER v1 - Risk-Controlled Development Foundation          |
//| Platform: MetaTrader 5                                           |
//| Initial signals: EMA crossover                                   |
//| Live execution: DISABLED                                         |
//+------------------------------------------------------------------+
#property strict
#property version "1.10"

#include <Trade/Trade.mqh>

CTrade trade;

//--- Strategy settings
input int FastEMA = 9;
input int SlowEMA = 21;
input int ATRPeriod = 14;
input double StopLossATR = 1.5;
input double RewardRiskRatio = 3.0;

//--- Risk settings
input double RiskPercent = 1.0;
input double FixedLotSize = 0.01;
input bool UseRiskBasedVolume = true;
input double MaxDailyLossPercent = 3.0;
input int MaxPositions = 1;
input ulong MagicNumber = 210001;

//--- Safety settings
input bool EnableLiveTrading = false;
input int MaxSpreadPoints = 100;
input int SlippagePoints = 20;

//--- Indicator handles
int fastHandle = INVALID_HANDLE;
int slowHandle = INVALID_HANDLE;
int atrHandle = INVALID_HANDLE;

datetime lastBarTime = 0;
int dayOfYear = -1;
double dayStartEquity = 0.0;
bool dailyLock = false;

//+------------------------------------------------------------------+
int OnInit()
{
   if(FastEMA <= 0 ||
      SlowEMA <= FastEMA ||
      ATRPeriod <= 0 ||
      StopLossATR <= 0 ||
      RewardRiskRatio <= 0 ||
      RiskPercent <= 0 ||
      RiskPercent > 1.0 ||
      FixedLotSize <= 0 ||
      MaxDailyLossPercent <= 0 ||
      MaxDailyLossPercent > 100 ||
      MaxPositions < 1 ||
      MaxSpreadPoints <= 0)
   {
      Print("Invalid settings. Check the inputs.");
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
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   ResetDailyBaseline();

   Print("DEMO TRADER initialized on ", _Symbol);
   Print("Live execution setting: ", EnableLiveTrading);
   Print("This is a development foundation, not a validated strategy.");

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
void ResetDailyBaseline()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   dayOfYear = dt.day_of_year;
   dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   dailyLock = false;

   Print("Daily equity baseline reset: ", dayStartEquity);
}

//+------------------------------------------------------------------+
bool CheckDailyLoss()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day_of_year != dayOfYear)
      ResetDailyBaseline();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   if(dayStartEquity <= 0 || equity <= 0)
   {
      dailyLock = true;
      return false;
   }

   double lossPercent =
      100.0 * (dayStartEquity - equity) / dayStartEquity;

   if(lossPercent >= MaxDailyLossPercent)
   {
      dailyLock = true;
      Print("Daily loss limit reached. New entries blocked.");
   }

   return !dailyLock;
}

//+------------------------------------------------------------------+
int CountOwnPositions()
{
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);

      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
double NormalizeVolumeDown(double volume)
{
   double minVolume =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double maxVolume =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double step =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(minVolume <= 0 || maxVolume < minVolume || step <= 0)
      return 0.0;

   if(volume < minVolume)
      return 0.0;

   volume = MathMin(volume, maxVolume);

   // Round down so normalization does not increase risk.
   volume = MathFloor(volume / step + 1e-9) * step;

   if(volume < minVolume)
      return 0.0;

   return NormalizeDouble(volume, 8);
}

//+------------------------------------------------------------------+
double CalculateVolume(ENUM_ORDER_TYPE orderType,
                       double entryPrice,
                       double stopPrice)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   if(equity <= 0)
      return 0.0;

   double riskMoney = equity * RiskPercent / 100.0;

   double oneLotProfit = 0.0;

   if(!OrderCalcProfit(orderType, _Symbol, 1.0,
                       entryPrice, stopPrice, oneLotProfit))
   {
      Print("Cannot calculate stop-loss risk. Trade skipped.");
      return 0.0;
   }

   double oneLotLoss = MathAbs(oneLotProfit);

   if(oneLotLoss <= 0)
      return 0.0;

   double volume;

   if(UseRiskBasedVolume)
      volume = riskMoney / oneLotLoss;
   else
      volume = FixedLotSize;

   volume = NormalizeVolumeDown(volume);

   if(volume <= 0)
   {
      Print("Minimum broker volume exceeds the allowed risk.");
      return 0.0;
   }

   // Check the estimated loss at the normalized volume.
   double estimatedProfit = 0.0;

   if(!OrderCalcProfit(orderType, _Symbol, volume,
                       entryPrice, stopPrice, estimatedProfit))
   {
      return 0.0;
   }

   double estimatedLoss = MathAbs(estimatedProfit);

   // Never round volume upward to force a trade.
   if(UseRiskBasedVolume && estimatedLoss > riskMoney * 1.001)
   {
      Print("Estimated loss exceeds risk budget. Trade skipped.");
      return 0.0;
   }

   return volume;
}

//+------------------------------------------------------------------+
bool CheckMargin(ENUM_ORDER_TYPE orderType,
                 double volume,
                 double price)
{
   double requiredMargin = 0.0;

   if(!OrderCalcMargin(orderType, _Symbol, volume,
                       price, requiredMargin))
   {
      Print("Margin calculation failed. Trade skipped.");
      return false;
   }

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   if(requiredMargin <= 0 || requiredMargin > freeMargin)
   {
      Print("Insufficient free margin. Trade skipped.");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
void OnTick()
{
   // This foundation never sends orders while this is false.
   if(!EnableLiveTrading)
      return;

   if(!CheckDailyLoss())
      return;

   if(CountOwnPositions() >= MaxPositions)
      return;

   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar == 0 || currentBar == lastBarTime)
      return;

   lastBarTime = currentBar;

   double fast[3], slow[3], atr[3];

   if(CopyBuffer(fastHandle, 0, 0, 3, fast) != 3 ||
      CopyBuffer(slowHandle, 0, 0, 3, slow) != 3 ||
      CopyBuffer(atrHandle, 0, 0, 3, atr) != 3)
   {
      Print("Insufficient indicator data.");
      return;
   }

   // Completed-candle EMA crossover.
   bool buySignal =
      fast[2] <= slow[2] && fast[1] > slow[1];

   bool sellSignal =
      fast[2] >= slow[2] && fast[1] < slow[1];

   if(!buySignal && !sellSignal)
      return;

   MqlTick tick;

   if(!SymbolInfoTick(_Symbol, tick) || atr[1] <= 0)
      return;

   double spreadPoints = (tick.ask - tick.bid) / _Point;

   if(spreadPoints > MaxSpreadPoints)
   {
      Print("Spread exceeds configured limit. Trade skipped.");
      return;
   }

   ENUM_ORDER_TYPE orderType =
      buySignal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   double entryPrice =
      buySignal ? tick.ask : tick.bid;

   double stopDistance = atr[1] * StopLossATR;

   double minimumStop =
      (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)
      * _Point;

   if(stopDistance <= 0 || stopDistance < minimumStop)
   {
      Print("Stop distance is invalid or too small.");
      return;
   }

   double stopPrice;
   double targetPrice;

   if(buySignal)
   {
      stopPrice = entryPrice - stopDistance;
      targetPrice = entryPrice +
                    stopDistance * RewardRiskRatio;
   }
   else
   {
      stopPrice = entryPrice + stopDistance;
      targetPrice = entryPrice -
                    stopDistance * RewardRiskRatio;
   }

   stopPrice = NormalizeDouble(stopPrice, _Digits);
   targetPrice = NormalizeDouble(targetPrice, _Digits);

   double volume = CalculateVolume(orderType,
                                   entryPrice,
                                   stopPrice);

   if(volume <= 0)
      return;

   if(!CheckMargin(orderType, volume, entryPrice))
      return;

   // This order path is included for future testing.
   // Do not enable it until the EA is compiled and validated.
   bool sent = false;

   if(buySignal)
      sent = trade.Buy(volume, _Symbol, 0,
                       stopPrice, targetPrice,
                       "DemoTrader development BUY");
   else
      sent = trade.Sell(volume, _Symbol, 0,
                        stopPrice, targetPrice,
                        "DemoTrader development SELL");

   if(!sent)
   {
      Print("Order request failed: ",
            trade.ResultRetcode(), " ",
            trade.ResultRetcodeDescription());
   }
   else
   {
      Print("Order request accepted by trade interface. Verify execution.");
   }
}
//+------------------------------------------------------------------+