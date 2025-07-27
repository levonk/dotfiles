prompt = function() {
    return (new Date()).toLocaleTimeString() + " " + shellHelper().hostname() + ":" + db.getName() + "> ";
}