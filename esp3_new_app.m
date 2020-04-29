classdef esp3_new_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure    matlab.ui.Figure
        Menu        matlab.ui.container.Menu
        Menu2       matlab.ui.container.Menu
        GridLayout  matlab.ui.container.GridLayout
        TabGroup    matlab.ui.container.TabGroup
        Tab         matlab.ui.container.Tab
        Tab2        matlab.ui.container.Tab
        TabGroup2   matlab.ui.container.TabGroup
        Tab_2       matlab.ui.container.Tab
        Tab2_2      matlab.ui.container.Tab
        TabGroup3   matlab.ui.container.TabGroup
        Tab_3       matlab.ui.container.Tab
        UIAxes      matlab.ui.control.UIAxes
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'ESP3';

            % Create Menu
            app.Menu = uimenu(app.UIFigure);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.UIFigure);
            app.Menu2.Text = 'Menu2';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [1 2];
            app.TabGroup.Layout.Column = [1 2];

            % Create Tab
            app.Tab = uitab(app.TabGroup);
            app.Tab.Title = 'Tab';

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';
            

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.GridLayout);
            app.TabGroup2.Layout.Row = [1 2];
            app.TabGroup2.Layout.Column = [3 4];

            % Create Tab_2
            app.Tab_2 = uitab(app.TabGroup2);
            app.Tab_2.Title = 'Tab';

            % Create Tab2_2
            app.Tab2_2 = uitab(app.TabGroup2);
            app.Tab2_2.Title = 'Tab2';
            
            % Create TabGroup3
            app.TabGroup3 = uitabgroup(app.GridLayout);
            app.TabGroup3.Layout.Row = [3 6];
            app.TabGroup3.Layout.Column = [1 4];
            
            % Create Tab_3
            app.Tab_3 = uitab(app.TabGroup3);
            app.Tab_3.Title = 'Tab';

            % Create UIAxes
            app.UIAxes = uiaxes(app.Tab_3);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')


            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = esp3_new_app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end
        

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end