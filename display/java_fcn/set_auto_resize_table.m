function jTable=set_auto_resize_table(tableH)

jScroll = findjobj(tableH);
jTable = jScroll.getViewport.getView;
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
