from matplotlib import pyplot as plt

from managers.managers import DataManager
from estimation.estimation import ShortEstimation, LongEstimation
import pandas

manager = DataManager()

manager.fetch_new_ticker("AAPL", auto_update=False)
manager.fetch_new_ticker("MSFT", auto_update=False)

manager.update_data()

forecaster = ShortEstimation(horizon=21, window_size=21)
long_forecaster = LongEstimation()
result = long_forecaster.estimate(manager.get_ticker_data("MSFT"))

#must use get_ticker_data because it adds EPS data to dataframe to help with predictions
pred_price, real_price = forecaster.estimate(manager.get_ticker_data("MSFT"))
#must use update_preds function because the manager object is not connected to estimation function
#and cannot be done automatically
print(manager.update_preds("MSFT", pred_price))

# code below grabs prediction data automatically from short_predictions
#manager.short_predictions.index.get_level_values(1).unique().values --> displays all of
#ticker_data = manager.short_predictions.xs(ticker.upper(), axis=0, level=1)

#long avg preds
plt.plot(result.index, result["yhat"], marker='o', linestyle='-', color='g')
#long lower preds
plt.plot(result.index, result["yhat_lower"], marker='o', linestyle='-', color='b')
#long upper preds
plt.plot(result.index, result["yhat_upper"], marker='o', linestyle='-', color='b')

#short test prices
plt.plot(pred_price.index, pred_price, marker='o', linestyle='-', color='r')

#real test prices
plt.plot(real_price.index, real_price, marker='o', linestyle='-', color='g')

#plt.plot(len(real_price), real_price, marker='o', linestyle='-', color='b')
plt.xlabel('Date')
plt.ylabel('Close')
plt.grid()
plt.show()