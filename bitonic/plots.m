close all; clear; clc;

results = csvread('results.csv', 1, 0);
size= results(:,1);
threads = results(:,2);
impbitserial = results(:,3);
recbitserial = results(:,4);
qsort = results(:,5);
pthread = results(:,6);
omp = results(:,7);
cilk = results(:,8);

for i=0:8:64
    fig = figure;
    ax = axes('Parent',fig,'XMinorTick','on','XScale','log',...
        'XTick',[2 4 8 16 32 64 128 256]);
    box on;
    axis tight;
    hold on;
    plot(threads((i+1):(i+8)), qsort((i+1):(i+8))./pthread((i+1):(i+8)))
    plot(threads((i+1):(i+8)), qsort((i+1):(i+8))./omp((i+1):(i+8)))
    plot(threads((i+1):(i+8)), qsort((i+1):(i+8))./cilk((i+1):(i+8)))
    xlabel('Threads');
    ylabel('Percent Speedup');
    str = sprintf('Speedup in relation to number of threads\nSize = 2^{%d}', ...
        size(1+i));
    title(str);
    yt = get(ax, 'ytick');
    ytl = strcat(strtrim(cellstr(num2str(yt'*100))), '%');
    set(ax, 'yticklabel', ytl);
    legend('Pthreads', 'OpenMP', 'Cilk');
    str = sprintf('report/figures/figure-3.%d.png', i/8 +1);
    set(ax,'FontSize',16);
    hold off;
%     fig.Position = [100 100 600 500];
    print(fig, str, '-dpng', '-r300');
end


for i=1:8
    fig = figure;
    ax = axes('Parent', fig,...
        'XTickLabel',{'2^{16}','2^{17}','2^{18}','2^{19}','2^{20}','2^{21}','2^{22}','2^{23}','2^{24}'});
    box on;
    axis tight;
    hold on;
    plot(size(i:8:(i+64)), qsort(i:8:(i+64))./pthread(i:8:(i+64)))
    plot(size(i:8:(i+64)), qsort(i:8:(i+64))./omp(i:8:(i+64)))
    plot(size(i:8:(i+64)), qsort(i:8:(i+64))./cilk(i:8:(i+64)))
    xlabel('Size');
    ylabel('Percent Speedup');
    str = sprintf('Speedup in relation to size\nThreads = %d', threads(i));
    title(str);
    yt = get(ax, 'ytick');
    ytl = strcat(strtrim(cellstr(num2str(yt'*100))), '%');
    set(ax, 'yticklabel', ytl);
    legend('Pthreads', 'OpenMP', 'Cilk');
    set(gca,'FontSize',16)
    str = sprintf('report/figures/figure-4.%d.png', i);
    set(ax,'FontSize',16);
    hold off;
%     fig.Position = [100 100 600 500];
    print(fig, str, '-dpng', '-r300');
end


fig = figure;
labels = {sprintf('Imperative Bitonic Sort (serial)'), ...
          sprintf('Recursive Bitonic Sort (serial)'), ...
          sprintf('Quicksort'), ...
          sprintf('Recursive Bitonic Sort (Pthread)'), ...
          sprintf('Recursive Bitonic Sort (OpenMP)'), ...
          sprintf('Recursive Bitonic Sort (Cilk)')};
ax = axes('Parent', fig, ...
    'YTick',[], ...
    'XTickLabel', labels, ...
    'XTick', [1 2 3 4 5 6]);
box on;
hold on;
x = 1:6;
y = [impbitserial(67), recbitserial(67), qsort(67), pthread(67), omp(67), cilk(67)];
bar(y);
text(x, y', num2str(y','%0.3fs'), ...
     'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'bottom', ...
     'FontSize', 11);
fix_xticklabels(ax, 0.1, {'FontSize',12});
str = sprintf('Clock time for each method, Size=2^{24}, Threads=2^3');
title(str);
ylabel('Time');
set(ax,'FontSize',12);
fig.Position = [100 100 900 450];
% print(fig, 'report/figures/figure-5.png', '-dpng', '-r300');


