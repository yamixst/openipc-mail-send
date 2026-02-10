#!/usr/bin/haserl
<%in p/common.cgi %>
<%
page_title="Mail"
config_file=/etc/webui/mail.conf
params="enabled from to password subject body user smtp_host smtp_port interval crontab heif"

# webhook for remote send, returns [t|f]
if [ "$GET_send" = "image" ]; then
	echo "Content-type: text/html; charset=UTF-8"
	echo
	result=$(/usr/bin/mail 2>&1)
	if [ $? -eq 0 ]; then
		echo "true"
	else
		echo "false"
	fi
	exit 0
fi

if [ "$REQUEST_METHOD" = "POST" ]; then
	for p in $params; do
		eval mail_${p}=\$POST_mail_${p}
	done

	if [ "$mail_enabled" = "true" ]; then
		[ -z "$mail_from" ] && set_error_flag "Sender mail cannot be empty."
		[ -z "$mail_to" ] && set_error_flag "Recipient mail cannot be empty."
		[ -z "$mail_password" ] && set_error_flag "Mail password cannot be empty."
	fi

	if [ -z "$error" ]; then
		rm -f "$config_file"
		for p in $params; do
			echo "mail_${p}=\"$(eval echo \$mail_${p})\"" >> "$config_file"
		done

		sed -i /mail/d /etc/crontabs/root
		if [ "$mail_enabled" = "true" ] && [ "$mail_crontab" = "true" ]; then
			echo "*/${mail_interval} * * * * /usr/bin/mail" >> /etc/crontabs/root
		fi

		redirect_back "success" "Mail config updated."
	fi

	redirect_to "$SCRIPT_NAME"
fi

[ -e "$config_file" ] && include $config_file
[ -z "$mail_crontab" ] && mail_crontab="false"
[ -z "$mail_interval" ] && mail_interval="15"
%>

<%in p/header.cgi %>
	<div class="alert alert-info">
		<dl>
			<dt class="cp2cb">http://root:12345@<%= $network_address %>/cgi-bin/ext-mail.cgi?send=image</dt>
			<dd>Use this webhook url for remote call to send image via mail.</dd>
		</dl>
	</div>

<form action="<%= $SCRIPT_NAME %>" method="post">
	<% field_switch "mail_enabled" "Enable Mail" "eval" %>
	<div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4 mb-4">
		<div class="col">
			<% field_text "mail_from" "From" "Sender mail address." %>
			<% field_text "mail_to" "To" "Recipient mail address." %>
			<% field_password "mail_password" "Password" "SMTP authentication password. For Gmail, use App Password." %>
			<% field_text "mail_user" "SMTP User" "SMTP username (optional, defaults to From address)." %>
		</div>

		<div class="col">
			<% field_text "mail_smtp_host" "SMTP Host" "SMTP server host (optional, auto-detected from mail domain)." %>
			<% field_text "mail_smtp_port" "SMTP Port" "SMTP server port (optional, default: 587)." %>
			<% field_text "mail_subject" "Subject" "Mail subject. Placeholders: %hostname, %datetime, %soctemp" %>
			<% field_text "mail_body" "Body" "Mail body text. Placeholders: %hostname, %datetime, %soctemp" %>
		</div>

		<div class="col">
			<% field_switch "mail_crontab" "Add to Crontab" "eval" "Send pictures timed by interval." %>
			<% field_string "mail_interval" "Interval" "eval" "15 30 60 120" "Minutes between submissions." %>
			<% field_switch "mail_heif" "Use HEIF format" "eval" "Requires H265 codec on Video0." %>
		</div>

		<div class="col">
			<% [ -e "$config_file" ] && ex "cat $config_file" %>
			<% ex "grep /usr/bin/mail /etc/crontabs/root" %>
		</div>
	</div>
	<% button_submit %>
</form>

<script>
<% if [ "$mail_crontab" = "true" ]; then %>
	$('#mail_crontab').checked = true;
<% fi %>

<% if [ "$(yaml-cli -g .video0.codec)" != "h265" ]; then %>
	$('#mail_heif').checked = false;
	$('#mail_heif').disabled = true;
<% fi %>
</script>

<%in p/footer.cgi %>
