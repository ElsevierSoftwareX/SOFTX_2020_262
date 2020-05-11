function tbar=create_default_toolbar(fig)

set(fig,'Toolbar','none')
tbar=uitoolbar(fig);
uitoolfactory(tbar,'Exploration.ZoomIn');
uitoolfactory(tbar,'Exploration.ZoomOut');
uitoolfactory(tbar,'Exploration.Pan');
uitoolfactory(tbar,'Exploration.Rotate');
uitoolfactory(tbar,'Standard.PrintFigure');
