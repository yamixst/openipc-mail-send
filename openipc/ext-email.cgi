#!/usr/bin/haserl
<%in p/common.cgi %>
<%
page_title="Email"
config_file=/etc/webui/email-snapshot.conf
params="enabled from to password subject body user smtp_host smtp_port interval crontab heif"

# webhook for remote send, returns [t|f]
if [ "$GET_send" = "image" ]; then
	echo "Content-type: text/html; charset=UTF-8"
	echo
	result=$(/usr/sbin/email-snapshot 2>&1)
	if [ $? -eq 0 ]; then
		echo "true"
	else
		echo "false"
	fi
	exit 0
fi

if [ "$REQUEST_METHOD" = "POST" ]; then
	for p in $params; do
		eval email_${p}=\$POST_email_${p}
	done

	if [ "$email_enabled" = "true" ]; then
		[ -z "$email_from" ] && set_error_flag "Sender email cannot be empty."
		[ -z "$email_to" ] && set_error_flag "Recipient email cannot be empty."
		[ -z "$email_password" ] && set_error_flag "Email password cannot be empty."
	fi

	if [ -z "$error" ]; then
		rm -f "$config_file"
		for p in $params; do
			echo "email_${p}=\"$(eval echo \$email_${p})\"" >> "$config_file"
		done

		sed -i /email-snapshot/d /etc/crontabs/root
		if [ "$email_enabled" = "true" ] && [ "$email_crontab" = "true" ]; then
			echo "*/${email_interval} * * * * /usr/sbin/email-snapshot" >> /etc/crontabs/root
		fi

		redirect_back "success" "Email config updated."
	fi

	redirect_to "$SCRIPT_NAME"
fi

[ -e "$config_file" ] && include $config_file
[ -z "$email_crontab" ] && email_crontab="false"
[ -z "$email_interval" ] && email_interval="15"
%>

<%in p/header.cgi %>
	<div class="alert alert-info">
		<dl>
			<dt class="cp2cb">http://root:12345@<%= $network_address %>/cgi-bin/ext-email.cgi?send=image</dt>
			<dd>Use this webhook url for remote call to send image via email.</dd>
		</dl>
	</div>

<form action="<%= $SCRIPT_NAME %>" method="post">
	<% field_switch "email_enabled" "Enable Email" "eval" %>
	<div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4 mb-4">
		<div class="col">
			<% field_text "email_from" "From" "Sender email address." %>
			<% field_text "email_to" "To" "Recipient email address." %>
			<% field_password "email_password" "Password" "SMTP authentication password. For Gmail, use App Password." %>
			<% field_text "email_user" "SMTP User" "SMTP username (optional, defaults to From address)." %>
		</div>

		<div class="col">
			<% field_text "email_smtp_host" "SMTP Host" "SMTP server host (optional, auto-detected from email domain)." %>
			<% field_text "email_smtp_port" "SMTP Port" "SMTP server port (optional, default: 587)." %>
			<% field_text "email_subject" "Subject" "Email subject. Placeholders: %hostname, %datetime, %soctemp" %>
			<% field_text "email_body" "Body" "Email body text. Placeholders: %hostname, %datetime, %soctemp" %>
		</div>

		<div class="col">
			<% field_switch "email_crontab" "Add to Crontab" "eval" "Send pictures timed by interval." %>
			<% field_string "email_interval" "Interval" "eval" "15 30 60 120" "Minutes between submissions." %>
			<% field_switch "email_heif" "Use HEIF format" "eval" "Requires H265 codec on Video0." %>
		</div>

		<div class="col">
			<% [ -e "$config_file" ] && ex "cat $config_file" %>
			<% ex "grep email-snapshot /etc/crontabs/root" %>
		</div>
	</div>
	<% button_submit %>
</form>

<script>
<% if [ "$email_crontab" = "true" ]; then %>
	$('#email_crontab').checked = true;
<% fi %>

<% if [ "$(yaml-cli -g .video0.codec)" != "h265" ]; then %>
	$('#email_heif').checked = false;
	$('#email_heif').disabled = true;
<% fi %>
</script>

<%in p/footer.cgi %>
