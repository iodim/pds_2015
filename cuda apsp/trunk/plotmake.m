clc; clear; close all;

data = readtable('results.csv');

p = [0.33, 0.45, 0.67];

for i=1:3
    selector = data.p == p(i);
    n = data.n(selector);
    s = data.Serial(selector);
    m1 = data.Method_1(selector);
    m2 = data.Method_2(selector);
    m3 = data.Method_3(selector);
    m4 = data.Method_4(selector);
    figure
        hold on;
        box on;
        plot(n, s./m1, 'LineWidth', 1.125);
        plot(n, s./m2, 'LineWidth', 1.125);
        plot(n, s./m3, 'LineWidth', 1.125);
        plot(n, s./m4, 'LineWidth', 1.125);
        grid on;
        
        l = legend('1 c/t, w/o SM', ...
                   '1 c/t, w/ SM', ...
                   '2 c/t, w/ SM', ...
                   '4 c/t, w/ SM', ...
                   'Location', 'northwest');
        set(l, 'Interpreter', 'Latex');
        set(l, 'Fontsize', 11);
        
        set(gca, 'XTick', n);
        xt = get(gca, 'XTick');
        str = cellstr( num2str(xt(:),'$2^{%d}$') );
        set(gca, 'XTickLabel', str);
        
        yt = get(gca, 'YTick');
        str = cellstr( num2str(yt(:), '%d00\\%%'));
        set(gca, 'YTickLabel', str);
        
        set(gca, 'FontSize', 11);
        xlabel('$n$', 'Interpreter', 'Latex', 'FontSize', 11);
        ylabel('Percent Speedup', 'Interpreter', 'Latex', 'FontSize', 11);
        matlab2tikz(['../report/figures/figure-' num2str(i) '.tikz'], ...
            'height', '\figureheight', 'width', '\figurewidth', ...
            'showInfo', false)
end