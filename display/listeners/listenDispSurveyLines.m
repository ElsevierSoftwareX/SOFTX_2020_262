function listenDispSurveyLines(src,listdata,main_figure)
main_menu=getappdata(main_figure,'main_menu');
set(main_menu.disp_survey_lines,'checked',listdata.AffectedObject.DispSurveyLines);

toggle_disp_survey_lines(main_figure);
end