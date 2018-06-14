
$.fn.feedback = function (o) {

    /**
     * requires > boostrap 3.x.x
     * argument :
     * {
     *   feedback_bar : "feedback_bar_classname" (class of a ul in cotnainer - REQUIRED)
     *   deafault_score : n (a int)
     *   output : feedback_output
     *   comment_bar : {
     *      container : "feedback_comment_container_classname", (a div with a textarea),
     *      always_visible : bool,
     *      open_on  : int
     *   }
     *  on_image : 
     *  off_image : 
     * }
     */

    if (o.feedback_bar == null) {
        console.log("property `feedback_bar` must be set as property of passed object (value must be the classname of a `ul` to hold the feedback buttons)");
        return;
    }
    var feedback_score = o.deafault_score == null ? 4 : o.deafault_score;
    var feedback_stars = this.children("." + o.feedback_bar).children("li");

    var has_comment_input = o.comment_bar == null ? false : true;
    var comment_alawys_visible = false;
    var comment_input = null;
    var comment_score_trigger = null;

    var feedback_output = o.output == null ? false : o.output;

    var feedback_stars_class_on = o.on_class != null ? o.on_class : "glyphicon-star-empty";
    var feedback_stars_class_off = o.off_class != null ? o.off_class : "glyphicon-star";

    if (feedback_output != false) {
        feedback_output = this.children("." + feedback_output);
        feedback_output.val(feedback_score);
    }

    if (has_comment_input) {
        //set up some inline styles..
        comment_alawys_visible = o.comment_bar.always_visible == null ? false : o.comment_bar.always_visible;
        comment_input = this.children("." + o.comment_bar.container).children("textarea")[0];
        comment_score_trigger = o.comment_bar.open_on == null ? 4 : o.comment_bar.open_on;
        this.children("." + o.comment_bar.container).css("overflow", "hidden");
        if (feedback_score > comment_score_trigger) {
            this.children("." + o.comment_bar.container).css("display", "none");
        }
    }

    $.each(feedback_stars, function (k, v) {
        var star = v;
        var star_val = star.getAttribute("x-score");
        $(star).on("click", function (e) {
            feedback_score = star_val;
            if (feedback_output != false) {
                feedback_output.val(feedback_score);
            }
            if (has_comment_input) {
                if (comment_alawys_visible != true) {
                    if (feedback_score <= comment_score_trigger) {
                        $("." + o.comment_bar.container).slideDown();
                    } else {
                        $("." + o.comment_bar.container).slideUp();
                    }
                }
            }
            draw_rating(feedback_score);
        });

        $(star).on("mouseout", function (e) {
            draw_rating(feedback_score);
        });

        //For debugging
        $(star).on("mouseover", function (e) {
            console.log(star_val);
            draw_rating(star_val);
        });
    });

    draw_rating(feedback_score);



    function draw_rating(fromvalue) {
        var unpinned = get_unpinned(fromvalue);
        unpinned.find("span").removeClass(feedback_stars_class_on);
        unpinned.find("span").addClass(feedback_stars_class_off);
        unpinned.css("color", "#000");
        var pinned = get_pinned(fromvalue);
        pinned.find("span").removeClass(feedback_stars_class_off);
        pinned.find("span").addClass(feedback_stars_class_on);
        pinned.css("color", "#FFE303");
    }

    function get_unpinned(fromvalue) {
        return $("[x-score]").filter(function () {
            return Number($(this).attr("x-score")) > fromvalue;
        });
    }

    function get_pinned(fromvalue) {
        return $("[x-score]").filter(function () {
            return Number($(this).attr("x-score")) <= fromvalue;
        });
    }
}