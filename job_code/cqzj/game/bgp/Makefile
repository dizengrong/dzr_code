####################################################################
## @author QingliangCn <qing.liang.cn@gmail.com>
## @datetime 2011-11-21
## @description beam文件被放在ebin
##
####################################################################

##指定当前项目在svn仓库中的名字
APP_NAME := bgp
SRC_DIRS := src/*.erl
include ../../../hrl/include.mk

##使用通配符方式指定每个文件的编译规则
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<