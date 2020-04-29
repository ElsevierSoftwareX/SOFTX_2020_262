function reactivate_keyboard_func(src,callbackdata,main_figure)

replace_interaction(src,'interaction','KeyPressFcn','id',1,'interaction_fcn',{@keyboard_func,main_figure});

end