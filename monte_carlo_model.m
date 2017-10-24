import java.util.LinkedList

time_limit = 10000;
max_line = 80;
limit_count = 0;

% 0 = stoplight
% 1 = never yield
% 2 = x-priority
% 3 = never yield up to N
mode = 3;

light_length = 12;
rate_x = 0.41;
rate_y = 0.09;

x_queue = LinkedList();
y_queue = LinkedList();

light_time = 0;
current_direction = 0;
switched = 0;
cars_since_switch = 0;
consecutive_limit = 10;

S = zeros(max_line, max_line);
W = zeros(2 * max_line, 1);


for t = 1 : time_limit
	
	% generate cars from poisson process
	for i = 1 : poissrnd(rate_x)
		if x_queue.size() < max_line - 1
			x_queue.add(0);
		else
			limit_count = limit_count + 1;
		end
	end
	
	for i = 1 : poissrnd(rate_y)
		if y_queue.size() < max_line - 1
			y_queue.add(0);
		else
			limit_count = limit_count + 1;
		end
	end
	
	% allow 1 car to pass in the correct direction
	if switched == 0
		if current_direction == 0 && x_queue.size() > 0
			wait = x_queue.removeFirst();
			W(wait + 1) = W(wait + 1) + 1;
			cars_since_switch = cars_since_switch + 1;
		elseif current_direction == 1 && y_queue.size() > 0
			wait = y_queue.removeFirst();
			W(wait + 1) = W(wait + 1) + 1;
			cars_since_switch = cars_since_switch + 1;
		end
	end
	
	% increment wait times for all remaining cars
	for i = 0 : x_queue.size() - 1
		x_queue.set(i, x_queue.get(i) + 1);
	end
	
	for i = 0 : y_queue.size() - 1
		y_queue.set(i, y_queue.get(i) + 1);
	end
	
	% update crossing direction
	switched = 0;
	if mode == 0
		% stoplight mode
		light_time = light_time + 1;
		if light_time >= light_length
			light_time = 0;
			current_direction = 1 - current_direction;
			switched = 1;
		end
	elseif mode == 1
		% never yield mode
		if current_direction == 0 && x_queue.size() == 0 && y_queue.size() > 0
			current_direction = 1;
			switched = 1;
		elseif current_direction == 1 && y_queue.size() == 0 && x_queue.size() > 0
			current_direction = 0;
			switched = 1;
		end
	elseif mode == 2
		% x-priority mode
		if current_direction == 0 && x_queue.size() == 0 && y_queue.size() > 0
			current_direction = 1;
			switched = 1;
		elseif current_direction == 1 && x_queue.size() > 0
			current_direction = 0;
			switched = 1;
		end
	elseif mode == 3
		% never yield up to N
		if current_direction == 0 && y_queue.size() > 0 ...
				&& (x_queue.size() == 0 || cars_since_switch >= consecutive_limit)
			current_direction = 1;
			switched = 1;
			cars_since_switch = 0;
		elseif current_direction == 1 && x_queue.size() > 0 ...
				&& (y_queue.size() == 0 || cars_since_switch >= consecutive_limit)
			current_direction = 0;
			switched = 1;
			cars_since_switch = 0;
		end
	end
	
	x = x_queue.size();
	y = y_queue.size();
	
	% update cumulative state
	S(x + 1, y + 1) = S(x + 1, y + 1) + 1;
	
end

if limit_count / time_limit > 0.1
	disp('DIVERGENT');
end

S = S / time_limit;
W = W / sum(W);

% plot stationary state
figure;
plot_size = 8;
h_image = imagesc(flipud(S(1:plot_size, 1:plot_size)));
xlabel('Away From Cornell');
ylabel('Towards Cornell');

% flip y-axis
h_axis = get(h_image, 'Parent');
y_ticks = get(h_axis, 'YTickLabel');
set(h_axis, 'YTickLabel', flipud(y_ticks));

% set colors and legend
colormap hot;
colorbar;

% plot wait distribution
figure;
plot(0:19, W(1:20));
xlabel('Wait Time');
ylabel('Probability');

% expected wait time
expected_wait = 0;
variance_wait = 0;

for i = 1 : length(W)
	expected_wait = expected_wait + W(i) * (i - 1);
end

for i = 1 : length(W)
	variance_wait = variance_wait + W(i) * (i - 1 - expected_wait) ^ 2;
end

disp(expected_wait);
disp(variance_wait);






















