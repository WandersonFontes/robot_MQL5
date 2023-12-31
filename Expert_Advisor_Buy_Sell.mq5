#property copyright "Wanderson Fontes"
#property link      "https://github.com/WandersonFontes"
#property version   "1.00"

#include <Trade/Trade.mqh>

MqlRates candle[];

CTrade trade;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
    if (IsNewCandle()) {
        CopyRates(_Symbol, _Period, 0, 20, candle);
        ArraySetAsSeries(candle, true);
        double tr = ATRValue(1);
        double atr = ATRValue(14);

        double minTick = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

        if (MovingAverageCross() == 1 && IsVolumeIncreasing() && RsiValue() < 70 && tr < atr) {
            double stopLossValue = candle[1].close - tr * 2;
            stopLossValue = MathRound(stopLossValue / minTick) * minTick;
            trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, 200, 0, stopLossValue, 0, "Buy Order");
        } else if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if (MovingAverageCross() == -1 && !IsVolumeIncreasing() && RsiValue() > 30 && tr >= atr) {
                // Planned sell
                trade.Sell(200, _Symbol, 0, 0, 0, "Sell Order");
            } else {
                // Modify stop loss value in existing position

                double newStopLossValue = candle[1].close - tr * 2;
                newStopLossValue = MathRound(newStopLossValue / minTick) * minTick;

                if (newStopLossValue > PositionGetDouble(POSITION_SL) &&
                    newStopLossValue < PositionGetDouble(POSITION_PRICE_CURRENT)) {
                    trade.PositionModify(_Symbol, newStopLossValue, 0);
                }
            }
        }
    }
}

bool IsNewCandle()
{
    static datetime last_time = 0;
    datetime lastbar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
    if (last_time == 0) {
        last_time = lastbar_time;
        return false;
    }
    if (last_time != lastbar_time) {
        last_time = lastbar_time;
        return true;
    }
    return false;
}

int MovingAverageCross()
{
    int handleMMFast;
    double bufferMMFast[];

    int handleMMSlow;
    double bufferMMSlow[];

    handleMMFast = iMA(_Symbol, _Period, 5, 0, MODE_SMA, PRICE_CLOSE);
    handleMMSlow = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);

    CopyBuffer(handleMMFast, 0, 0, 5, bufferMMFast);
    ArraySetAsSeries(bufferMMFast, true);

    CopyBuffer(handleMMSlow, 0, 0, 5, bufferMMSlow);
    ArraySetAsSeries(bufferMMSlow, true);

    if (bufferMMFast[2] < bufferMMSlow[2] && bufferMMFast[1] > bufferMMSlow[1]) {
        return 1;
    } else if (bufferMMFast[2] > bufferMMSlow[2] && bufferMMFast[1] < bufferMMSlow[1]) {
        return -1;
    } else {
        return 0;
    }
}

bool IsVolumeIncreasing()
{
    int handleOBV;
    double bufferOBV[];

    handleOBV = iOBV(_Symbol, _Period, VOLUME_TICK);

    CopyBuffer(handleOBV, 0, 0, 7, bufferOBV);
    ArraySetAsSeries(bufferOBV, true);

    for (int i = 2; i < ArraySize(bufferOBV); i++) {
        if (bufferOBV[1] < bufferOBV[i]) {
            return false;
        }
    }

    return true;
}

double RsiValue()
{
    int handleRSI;
    double bufferRSI[];

    handleRSI = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);

    CopyBuffer(handleRSI, 0, 0, 2, bufferRSI);
    ArraySetAsSeries(bufferRSI, true);

    return bufferRSI[0];
}

double ATRValue(int period_size)
{
    int handleATR;
    double bufferATR[];

    handleATR = iATR(_Symbol, _Period, period_size);

    CopyBuffer(handleATR, 0, 0, 2, bufferATR);
    ArraySetAsSeries(bufferATR, true);

    return bufferATR[1];
}
