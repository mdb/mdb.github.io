//= require jquery/jquery
//= require underscore/underscore
//= require_tree

_.templateSettings = {
  evaluate : /\{\[([\s\S]+?)\]\}/g,
  interpolate : /\{\{([\s\S]+?)\}\}/g
};
