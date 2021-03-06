// Generated by CoffeeScript 2.5.1
(function() {
  Date.prototype.format = function(format = 'Y-MM-DD') {
    return moment(this).format(format);
  };

  Date.prototype.toDate = function() {
    return this;
  };

  Date.prototype.setEndOfDay = function() {
    this.setHours(23);
    this.setMinutes(59);
    this.setSeconds(59);
    return this;
  };

  Date.prototype.beginningOfMonth = function() {
    this.setDate(1);
    return this;
  };

  Date.prototype.addMilliseconds = function(value) {
    this.setMilliseconds(this.getMilliseconds() + value);
    return this;
  };

  Date.prototype.addSeconds = function(value) {
    return this.addMilliseconds(value * 1000);
  };

  Date.prototype.addMinutes = function(value) {
    return this.addMilliseconds(value * 60000);
  };

  Date.prototype.addHours = function(value) {
    return this.addMilliseconds(value * 3600000);
  };

  Date.prototype.addDays = function(value) {
    return this.addMilliseconds(value * 86400000);
  };

  Date.prototype.addWeeks = function(value) {
    return this.addMilliseconds(value * 604800000);
  };

  Date.prototype.addMonths = function(value) {
    var n;
    n = this.getDate();
    this.setDate(1);
    this.setMonth(this.getMonth() + value);
    this.setDate(Math.min(n, this.getDaysInMonth()));
    return this;
  };

  Date.prototype.addYears = function(value) {
    return this.addMonths(value * 12);
  };

  Date.prototype.getDaysInMonth = function() {
    return Date.getDaysInMonth(this.getFullYear(), this.getMonth());
  };

  Date.getDaysInMonth = function(year, month) {
    return [31, (anoBissexto(year) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month];
  };

}).call(this);
