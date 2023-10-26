a = 1;
#var true = 1;

#print("a = ", a, "\n");
if(a != 1) { die(); }
if(a != true) { die(); }

(func{a = 2})();

#print("a = ", a, "\n");
if(a != 2) { die(); }

(func{
    if(a != 2) { die(); }
    var a = 3;
    if(a != 3) { die(); }
    #print("a = ", a, "\n");
 })();

#print("a = ", a, "\n");
if(a != 2) { die(); }


(func(a=true){
    if(a != 1) { die(); }
})();

true_a = 0;
if(true_a != 0) { die(); }

my_hdg_true = true;
if (my_hdg_true != 1) { die(); }

# test true
setprop = func(a,b){
   if (b != "true") { die(); }
};
setprop("/sim/freeze/master",'true');

a=(true and 1);
if(a != true) { die(); }

a = { "key": true };
if(a["key"] != true) { die(); }

a = int("true");
if(a != true) { die(); }
