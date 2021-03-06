module = angular.module('impac.components.widgets-layouts.accounts-cash-balance', [])
module.controller('WidgetAccountsCashBalanceCtrl', ($scope, $q, $timeout, $filter, ImpacTheming, ImpacAssets, ImpacWidgetsSvc, HighchartsFactory) ->

  w = $scope.widget

  # Define settings
  # -------------------------------------
  $scope.orgDeferred = $q.defer()

  settingsPromises = [$scope.orgDeferred.promise]

  # Setup Highcharts Options
  # -------------------------------------
  getPeriod = ->
    w.metadata? && w.metadata.hist_parameters? && w.metadata.hist_parameters.period || 'MONTHLY'

  # Widget specific methods
  # --------------------------------------
  w.initContext = ->
    # TODO: what to do when the widget has no data?
    $scope.isDataFound = w.content.chart?

    # Custom chart legend
    $scope.groupedTable = w.content.grouped_table
    # TODO: theming config for positive/negative hex codes (or move to API)
    # chartColors = ImpacTheming.get().chartColors
    # Set chart accounts series colors by account bias ('positive' / 'negative')
    setSeriesColors(w.content.chart.series, { positive: '#3FC4FF', negative: '#e50228'})

    if hist = w.metadata.hist_parameters
      $scope.fromDate = hist.from
      $scope.toDate = hist.to

  $scope.legendItemOnClick = (account)->
    serie = $scope.chart? && $scope.chart.hc? && getSerieByAccount($scope.chart.hc.series, account)
    return unless serie
    visibility = if serie.visible then false else true
    serie.setVisible(visibility)

  $scope.getLegendItemCheckBox = (account)->
    serie = $scope.chart? && $scope.chart.hc? && getSerieByAccount($scope.chart.hc.series, account)
    return 'fa-check-square-o' unless serie
    if serie.visible then 'fa-check-square-o' else 'fa-square-o'

  $scope.getLegendItemIcon = (account)->
    serie = $scope.chart? && $scope.chart.hc? && getSerieByAccount($scope.chart.hc.series, account)
    if serie.type == 'area' then ImpacAssets.get('areaLegendIcon') else ImpacAssets.get('plotLineLegendIcon')

  $scope.getLegendItemColor = (account)->
    serie = $scope.chart? && $scope.chart.hc? && getSerieByAccount($scope.chart.hc.series, account)
    return '#000' unless serie
    serie.color

  getSerieByAccount = (series, account)->
    _.find(series, (serie)-> (serie.id || serie.options && serie.options.id) == account.id)

  setSeriesColors = (series, chartColors) ->
    groupedSeries = _.groupBy(series, (serie)-> serie.bias)
    for bias, series of groupedSeries
      continue unless chartColors[bias]
      palette = ImpacTheming.color.generateShadesPalette(chartColors[bias], series.length)
      for serie, i in series
        serie.color = palette[i]

  $scope.chartId = ->
    "cashBalanceChart-#{w.id}"

  updateLocked = false
  zoomMetadata = {}
  onZoom = (event) ->
    zoomMetadata = angular.merge w.metadata, {
      xAxis:
        max: event.max
        min: event.min
    }
    unless updateLocked
      updateLocked = true
      $timeout ->
        ImpacWidgetsSvc.update(w, { metadata: zoomMetadata }, false).finally(-> updateLocked = false)
      , 1000

  # Called after initContext - draws the chart using HighCharts
  w.format = ->
    $timeout ->
      _highChartOptions =
        chartType: 'line'
        currency: w.metadata.currency
        period: getPeriod()
        showToday: true
        showLegend: false

      # Add Custom Highchart Options.
      $scope.chart = new HighchartsFactory($scope.chartId(), w.content.chart.series, _highChartOptions)
      $scope.chart.addXAxisOptions({
        defaults: w.metadata.xAxis
        callback: onZoom
        })
      $scope.chart.removeLegend()

      $scope.chart.render()

  # Widget is ready: can trigger the "wait for settings to be ready"
  # --------------------------------------
  $scope.widgetDeferred.resolve(settingsPromises)
)
module.directive('widgetAccountsCashBalance', ->
  return {
    restrict: 'A',
    controller: 'WidgetAccountsCashBalanceCtrl'
  }
)
