%% Initialization
clc; clear; close all;

data = readtable('results.csv');

p = [0.33, 0.45, 0.67];

selector = data.p == p(2);
n = data.n(selector);
s = data.Serial(selector);

FW_single_tile_no_shared =  data.FW_single_tile_no_shared(selector);
FW_single_tile_shared =  data.FW_single_tile_shared(selector);
FW_two_tiles_shared =  data.FW_two_tiles_shared(selector);
FW_four_tiles_shared =  data.FW_four_tiles_shared(selector);

CFW_single_tile_no_shared =  data.CFW_single_tile_no_shared(selector);
CFW_single_tile_shared =  data.CFW_single_tile_shared(selector);
CFW_two_tiles_shared =  data.CFW_two_tile_shared(selector);
CFW_four_tiles_shared =  data.CFW_four_tiles_shared(selector);

LFW_single_tile_no_shared =  data.LFW_single_tile_no_shared(selector);
LFW_single_tile_shared =  data.LFW_single_tile_shared(selector);
LFW_two_tiles_shared =  data.LFW_two_tiles_shared(selector);
LFW_four_tiles_shared =  data.LFW_four_tiles_shared(selector);

%% Square topology, no coalescence
figure(1); 
    hold on; box on;
    plot(n, s./FW_single_tile_no_shared, 'LineWidth', 1.125);
    plot(n, s./FW_single_tile_shared, 'LineWidth', 1.125);
    plot(n, s./FW_two_tiles_shared, 'LineWidth', 1.125);
    plot(n, s./FW_four_tiles_shared, 'LineWidth', 1.125);
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
%     matlab2tikz(['../report/figures/figure-' num2str(1) '.tikz'], ...
%         'height', '\figureheight', 'width', '\figurewidth', ...
%         'showInfo', false)


%% Square topology, coalescence
figure(2); 
    hold on; box on;
    plot(n, s./CFW_single_tile_no_shared, 'LineWidth', 1.125);
    plot(n, s./CFW_single_tile_shared, 'LineWidth', 1.125);
    plot(n, s./CFW_two_tiles_shared, 'LineWidth', 1.125);
    plot(n, s./CFW_four_tiles_shared, 'LineWidth', 1.125);
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
%     matlab2tikz(['../report/figures/figure-' num2str(2) '.tikz'], ...
%         'height', '\figureheight', 'width', '\figurewidth', ...
%         'showInfo', false)


%% Line topology
figure(3); 
    hold on; box on;
    plot(n, s./LFW_single_tile_no_shared, 'LineWidth', 1.125);
    plot(n, s./LFW_single_tile_shared, 'LineWidth', 1.125);
    plot(n, s./LFW_two_tiles_shared, 'LineWidth', 1.125);
    plot(n, s./LFW_four_tiles_shared, 'LineWidth', 1.125);
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
%     matlab2tikz(['../report/figures/figure-' num2str(3) '.tikz'], ...
%         'height', '\figureheight', 'width', '\figurewidth', ...
%         'showInfo', false)
