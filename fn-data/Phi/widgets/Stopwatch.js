define([
        'jquery', 'knockout', 'text!./Stopwatch.html', 'kojqui/button'
], function(jquery, ko, htmlString) {

    function ViewModel(params) {
        var self = this;

        self.MODE = {
            STOPPED : 0,
            PAUSED : 1,
            RUNNING : 2,
        };

        self.mode = ko.observable(self.MODE.STOPPED);
        self.elapsedTime = ko.observable(0);
        self.elapsedTimeSeconds = ko.pureComputed(function() {
            return (self.elapsedTime() / 1000).toFixed(0);
        });

        self.startLabel = ko.pureComputed(function() {
            return self.mode() == self.MODE.RUNNING ? "Pause" : "Start";
        });

        self.startIcons = ko.pureComputed(function() {
            return self.mode() == self.MODE.RUNNING ? {
                primary : 'ui-icon-pause'
            } : {
                primary : 'ui-icon-play'
            };
        });

        function twoDigits(n) {
            if (n >= 10)
                return n.toString();
            else
                return '0' + n.toString();
        }

        self.hoursDisplay = ko.pureComputed(function() {
            return twoDigits(Math.floor(self.elapsedTimeSeconds() / 3600));
        });

        self.minutesDisplay = ko.pureComputed(function() {
            return twoDigits(Math.floor(self.elapsedTimeSeconds() / 60) % 60);
        });

        self.secondsDisplay = ko.pureComputed(function() {
            return twoDigits(self.elapsedTimeSeconds() % 60);
        });

        self.startTime = 0;
        self.runTime = 0;
        self.cumulatedTime = 50;

        self.startStopPause = function() {
            switch (self.mode()) {
            case self.MODE.STOPPED:
            case self.MODE.PAUSED:
                self.mode(self.MODE.RUNNING);
                break;
            case self.MODE.RUNNING:
                self.mode(self.MODE.PAUSED);
                self.cumulatedTime = self.elapsedTime();
                break;

            }

            if (self.mode() == self.MODE.RUNNING) {
                self.startTime = new Date();
                self.update();
            }
        }

        self.update = function() {
            if (self.mode() != self.MODE.RUNNING)
                return;

            var now = new Date();
            self.elapsedTime(self.cumulatedTime + (now - self.startTime));
            setTimeout(function() {
                self.update();
            }, 100);
        }

        self.clear = function() {
            self.cumulatedTime = 0;
            self.startTime = new Date();
            self.elapsedTime(0);
        }
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
