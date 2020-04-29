function axDefaultCreateFcn(hAxes, ~)
    try
        hAxes.Interactions = [];
        disableDefaultInteractivity(hAxes);
        hAxes.Toolbar = [];
    catch
        % ignore - old Matlab release
    end
end
